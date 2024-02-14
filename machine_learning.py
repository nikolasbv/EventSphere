#run with python and not python3

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
from sklearn.linear_model import LogisticRegression
import os

# Use an environment variable for the Firebase Admin SDK JSON file path.
# Set the 'FIREBASE_ADMINSDK_JSON' environment variable to the path where your JSON file is located.
# Example to set this in your environment:
# For Unix-based systems (Linux/macOS): export FIREBASE_ADMINSDK_JSON='/path/to/your/json'
# For Windows: set FIREBASE_ADMINSDK_JSON=C:\path\to\your\json

firebase_adminsdk_json_path = os.environ.get('FIREBASE_ADMINSDK_JSON', 'path/to/your/firebase-adminsdk.json')

if not firebase_admin._apps:
    cred = credentials.Certificate(firebase_adminsdk_json_path)
    firebase_admin.initialize_app(cred)
    
db = firestore.client()

#Fetching events and users from database
def fetch_events_to_dataframe():
    events_ref = db.collection('events')
    events = events_ref.stream()

    events_list = []

    for event in events:
        event_dict = event.to_dict()
        event_dict['id'] = event.id
        events_list.append(event_dict)

    events_df = pd.DataFrame(events_list)
    return events_df

def fetch_users_to_dataframe():
    users_ref = db.collection('Users')
    users = users_ref.stream()

    users_list = []

    for user in users:
        user_dict = user.to_dict()

        user_ref = db.collection('Users').document(user.id)
        user_ref.update({'homeEvents': []})
        
        user_dict['id'] = user.id  
        users_list.append(user_dict)

    users_df = pd.DataFrame(users_list)
    return users_df

events_df = fetch_events_to_dataframe()
users_df = fetch_users_to_dataframe()


#Events data processing
event_columns_to_keep = ['eventID', 'category', 'city', 'price']

filtered_events_df = events_df[event_columns_to_keep].copy()

filtered_events_df['price'] = pd.to_numeric(filtered_events_df['price'].replace('Free', 0.0), errors='coerce')

filtered_events_df['price'].fillna(0.0, inplace=True)

events_encoded = pd.get_dummies(filtered_events_df, columns=['category', 'city'])

scaler = MinMaxScaler()

columns_to_scale = events_encoded.columns.difference(['eventID'])

events_encoded[columns_to_scale] = scaler.fit_transform(events_encoded[columns_to_scale])

events_encoded['eventID'] = filtered_events_df['eventID']

column_order = ['eventID'] + [col for col in events_encoded if col != 'eventID']
events_encoded = events_encoded[column_order]


#Users data processing
user_columns_to_keep = ['id', 'likedEvents', 'dislikedEvents', 'bookmarkedEvents', 'myEvents']

filtered_users_df = users_df[user_columns_to_keep].copy()

for col in ['likedEvents', 'dislikedEvents', 'bookmarkedEvents', 'myEvents']:
    filtered_users_df[col] = filtered_users_df[col].apply(lambda x: x if isinstance(x, list) else [])

filtered_users_df = filtered_users_df[
    filtered_users_df['likedEvents'].str.len() +
    filtered_users_df['dislikedEvents'].str.len() +
    filtered_users_df['bookmarkedEvents'].str.len() +
    filtered_users_df['myEvents'].str.len() > 0
]


interaction_data = []

for idx, row in filtered_users_df.iterrows():
    user_events = {}

    for event_id in row['likedEvents'] if isinstance(row['likedEvents'], list) else []:
        user_events[event_id] = user_events.get(event_id, 0) + 1
    for event_id in row['bookmarkedEvents'] if isinstance(row['bookmarkedEvents'], list) else []:
        user_events[event_id] = user_events.get(event_id, 0) + 1
    for event_id in row['myEvents'] if isinstance(row['myEvents'], list) else []:
        user_events[event_id] = user_events.get(event_id, 0) + 1

    for event_id in row['dislikedEvents'] if isinstance(row['dislikedEvents'], list) else []:
        user_events[event_id] = user_events.get(event_id, 0) - 1

    interaction_data.append(user_events)

interaction_matrix = pd.DataFrame(interaction_data, index=filtered_users_df.index)

interaction_matrix.fillna(0, inplace=True)

altered_users_df = filtered_users_df.join(interaction_matrix)

altered_users_df.drop(['likedEvents', 'dislikedEvents', 'bookmarkedEvents', 'myEvents'], axis=1, inplace=True)


#Access the Firestore database
#Train the Linear Regression Model for every user seperatelly
#Store the reccomended events ids to each users 'homeEvents' list in the database
db = firestore.client()

user_event_predictions = pd.DataFrame(index=altered_users_df.index, columns=events_encoded['eventID'])

for user_index, user_preferences in altered_users_df.iterrows():
    
    user_doc_id = user_preferences['id']

    events_encoded_copy = events_encoded.copy()

    train_event_ids = user_preferences[user_preferences != 0].index.tolist()
    train_data = events_encoded[events_encoded['eventID'].isin(train_event_ids)]

    final_events = events_encoded_copy[~events_encoded_copy['eventID'].isin(train_event_ids)]
    final_events_copy = final_events.copy()

    if not train_data.empty:
        
        X_train = train_data.drop('eventID', axis=1)
        y_train = [user_preferences[event_id] for event_id in train_data['eventID']]

        model = LogisticRegression()
        model.fit(X_train, y_train)

        X_test = final_events_copy.drop('eventID', axis=1)

        predictions = model.predict(X_test)

        # Convert predictions to binary
        final_events_copy['show_to_user'] = [1 if x > 1.5 else 0 for x in predictions]

        user_event_predictions.loc[user_index] = final_events_copy['show_to_user']

        recommended_event_ids = final_events_copy[final_events_copy['show_to_user'] == 1]['eventID'].tolist()
        
        disliked_event_ids = filtered_users_df.loc[user_index]['dislikedEvents']
        final_recommended_event_ids = [event_id for event_id in recommended_event_ids if event_id not in disliked_event_ids]

        user_ref = db.collection('Users').document(user_doc_id)
        doc = user_ref.get()
        if doc.exists:
            user_ref.update({'homeEvents': final_recommended_event_ids})
        else:
            print(f"No document found for user ID {user_doc_id}")
    else:
        print(f"No training data available for user ID {user_doc_id}")

    print(f"Processed user {user_doc_id}")

