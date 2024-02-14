import firebase_admin
from firebase_admin import credentials, firestore, auth
import random
import string
from random_username.generate import generate_username
from datetime import datetime, timedelta
import requests
import urllib.parse
import json
from geopy.geocoders import Nominatim
import geohash
import subprocess
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

def delete_all_auth_users():
    all_users = auth.list_users().iterate_all()
    for user in all_users:
        auth.delete_user(user.uid)
        print(f'Deleted user {user.uid}')

delete_all_auth_users()

def delete_collection(collection):
    docs = db.collection(collection).stream()
    for doc in docs:
        db.collection(collection).document(doc.id).delete()

delete_collection('tickets')
delete_collection('savedEvents') 
delete_collection('events')  
delete_collection('Users')


'''def get_streets():
    overpass_url = "http://overpass-api.de/api/interpreter"
    overpass_query = f"""
    [out:json][timeout:25];
    area[name="Sydney"]->.searchArea;
    (
    way["highway"](area.searchArea);
    );
    out body;
    >;
    out skel qt;
    """
    response = requests.get(overpass_url, 
                            params={'data': overpass_query})
    data = response.json()

    # Extract street names
    streets = set()
    for element in data.get('elements', []):
        if 'tags' in element and 'name' in element['tags']:
            streets.add(element['tags']['name'])

    return list(streets)

# Example usage
city_streets = get_streets()
print(city_streets) '''


streets_athens = ["Sakkelariou", "Aigaiou", "Artakis", "Zografou", "Depasta", "Verras", "Byzantiou", "Kokkinopoulou", "Papagou", "Seleykeias"]
streets_patras = ["Korinthou", "Kanari", "Saxtouri", "Lontou", "Skopa", "Lindou", "Souniou", "Leykas", "Aristotelous", "Pantokratoros"]
streets_thessaloniki = ["Kleanthous", "Papafi", "Byzantiou", "Tsimiski", "Katsimidi", "Marathonos", "Valtetsiou", "Kanari", "Apollonos", "Karakasi"]
streets_seattle = ['South Portland Street', '53rd Avenue Northeast', 'North 101st Street', '31st Avenue Southwest', 'South Judkins Street', 'Howell Place', 'South Bateman Street', 'West Blaine Street', 'Post Alley', '9th Avenue West']
streets_toronto = ['Orphanage Mews', 'Gardiner Expressway Collector', 'Long Branch Loop', 'Comrie Terrace', 'Dog Pound', 'Avondale Avenue', 'Black Creek Boulevard', 'Hove Street', 'Grapevine Circle', 'Wansey Road']
streets_paris = ['Voie E/8', 'Esplanade André Chamson', 'Accès Plateforme Logistique', 'Mockingbird Drive', 'South 9th Street', 'Rue Auguste Comte', 'Hixson Cemetery Road', 'Chemin Baudin', 'Villa Carnot', 'Impasse des Deux Nèthes']
streets_london = ['Victoria Embankment', 'Northdene Gardens', 'Rawson Street', 'Chasemore Close', 'Oakleigh Close', 'Parkstone Avenue', 'Agate Road', 'Southbridge Place', 'Oaks Road', 'Kirkby Close']
streets_madrid = ['Calle Zubía', 'Calle del Oboe', 'Calle Benito Asenjo', 'Calle Casanare', 'Calle Puentecillo', 'Callejón de la Luz', 'Calle Hernández Rubín', 'Calle Yeseros', 'Calle de Josep Plá', 'Calle de Aytona']
streets_rome = ['Via di Settebagni', 'Via Cavalletti', 'Via Mario De Dominicis', 'Lungotevere Ripa', "Via dell'Aquilone", 'Via Lorenzo Litta', 'Via Castignano', 'Via Vittorio Codeluppi', 'Via Pietro Frattini', 'Via Cesare Tallone']
streets_berlin = ['Heinz-Prillwitz-Weg', 'Zernickstraße', 'In der Halde', 'Nagolder Pfad', 'An der Brauerei', 'Bollestraße', 'Weilburgstraße', 'Buchholzweg', 'Daumstraße', 'Kleinbauersweg']
streets_amsterdam = ['Kalverstraat', 'Noordkaapstraat', 'Cabralstraat', 'Gabriela Mistralstraat', 'Elementenstraat', 'Ernest Staesstraat', 'Vier Heemskinderenstraat', 'Korte Water', 'Nicolaas Witsenkade', 'Nesserhoek']
streets_sydney = ['Brightmore Lane', 'Hudson Avenue', 'Medway Lane', 'Dobson Street', 'Zane Close', "Pippa's Pass", 'Lowden Lane', 'Boots Lane', 'Iona Place', 'Lister Avenue',]

cities = ['Athens', 'Patras', 'Thessaloniki', 'Seattle', 'Toronto', 'Paris', 'London', 'Madrid', 'Rome', 'Berlin', 'Amsterdam', 'Sydney']

cities_and_streets = {
    'Athens': streets_athens, 
    'Patras': streets_patras,
    'Thessaloniki': streets_thessaloniki,
    'Seattle': streets_seattle,
    'Toronto': streets_toronto, 
    'Paris': streets_paris,
    'London': streets_london,
    'Madrid': streets_madrid,
    'Rome': streets_rome, 
    'Berlin': streets_berlin,
    'Amsterdam': streets_amsterdam,
    'Sydney': streets_sydney
}

categories = [
    "Sports", "Music", "Art", "Technology", "Food", "Health",
    "Education", "Networking", "Outdoors", "Entertainment"
]

def random_date_time():
    random_days = random.randint(13, 365)
    random_hour = random.randint(0, 23)
    random_minute = random.choice([0, 15, 30, 45])
    future_date = datetime.now() + timedelta(days=random_days)
    random_date_with_time = future_date.replace(hour=random_hour, minute=random_minute, second=0, microsecond=0)
    formatted_date = random_date_with_time.strftime("%d %B %Y at %H:%M:%S UTC+2")
    formatted_date = formatted_date.lstrip("0")
    return formatted_date

def random_firebase_timestamp():
    random_days = random.randint(13, 365)
    random_hour = random.randint(0, 23)
    random_minute = random.choice([0, 15, 30, 45])

    future_date = datetime.now() + timedelta(days=random_days)
    random_date_with_time = future_date.replace(hour=random_hour, minute=random_minute, second=0, microsecond=0)

    return random_date_with_time


def generate_random_price():
    price = random.choice([0.00] + [float(x) for x in range(5, 105, 5)])
    return "Free" if price == 0.00 else "{:.2f}".format(price)

adjectives = [
    'Amazing', 'Incredible', 'Exciting', 'Mystical', 'Elegant', 'Fancy', 'Grand', 'Classic',
    'Joyful', 'Lively', 'Magical', 'Spectacular', 'Vibrant', 'Enchanting', 'Glamorous', 'Stunning'
]

nouns = [
    'Gala', 'Concert', 'Festival', 'Gathering', 'Party', 'Celebration', 'Soiree', 'Event',
    'Bash', 'Extravaganza', 'Affair', 'Reception', 'Function', 'Banquet', 'Ball', 'Jamboree'
]

themes = [
'Night', 'Music', 'Dance', 'Magic', 'Mystery', 'Fantasy', 'Dream', 'Adventure',
'Stars', 'Elegance', 'Rhythm', 'Harmony', 'Jubilee', 'Serenade', 'Odyssey', 'Voyage'
]

def generate_event_title():
    adjective = random.choice(adjectives)
    noun = random.choice(nouns)
    theme = random.choice(themes)

    title = f"{adjective} {theme} {noun}"
    return title

action_words = ['Discover', 'Experience', 'Celebrate', 'Enjoy', 'Explore', 'Unveil', 'Embrace', 'Uncover']
event_phrases = ['the Magic of', 'the Wonders of', 'a Night of', 'the Secrets of', 'an Evening of', 'the Joy of']
special_words = ['Elegance', 'Mystery', 'Excitement', 'Entertainment', 'Enchantment', 'Melody', 'Harmony', 'Delight']

def generate_event_header():
    action_word = random.choice(action_words)
    event_phrase = random.choice(event_phrases)
    special_word = random.choice(special_words)
    
    header = f"{action_word} {event_phrase} {special_word}"
    return header

intro_phrases = [
    "Join us for an unforgettable experience at", 
    "Don't miss out on the spectacular event featuring", 
    "Get ready to be amazed by", 
    "Experience the ultimate celebration of"
]

main_content = [
    "a lineup of world-class performances.", 
    "an evening filled with exciting activities and entertainment.", 
    "a magical journey through music, dance, and art.", 
    "exclusive access to gourmet food and exquisite drinks."
]

closing_statements = [
    "Book your tickets now and be part of something extraordinary.",
    "Reserve your spot today and create unforgettable memories.",
    "This is a once-in-a-lifetime event you won't want to miss.",
    "Join us for a night of celebration, joy, and wonder."
]

def generate_event_description(event_name):
    intro = random.choice(intro_phrases) + " " + event_name + ", where you will enjoy " + random.choice(main_content)
    closing = random.choice(closing_statements)

    description = intro + " " + closing
    return description

keywords = [
'Exciting', 'Elegant', 'Innovative', 'Inspiring', 'Festive', 'Iconic',
'Spectacular', 'Creative', 'Dynamic', 'Thrilling'
]

phrases = [
'cultural extravaganza', 'musical journey', 'artistic display',
'culinary adventure', 'night of fun', 'celebration of talent',
'fusion of styles', 'evening of wonders', 'display of skills', 'showcase of creativity'
]

additional_sentences = [
"Join us for this unforgettable experience.",
"Be part of a journey that excites and inspires.",
"Immerse yourself in an event like no other.",
"Let your senses be captivated by our unique attractions.",
"Witness a spectacle that will leave you spellbound."
]

def generate_event_overview():
    keyword = random.choice(keywords)
    phrase = random.choice(phrases)
    additional_sentence = random.choice(additional_sentences)
    overview = f"{keyword} {phrase}. {additional_sentence}"
    return overview


def create_dummy_event(city, street, user_id, username):
    event_title = generate_event_title()
    first_letter = username[0].upper()

    geolocator = Nominatim(user_agent="dummy_event_generator")
    address = f"{street}, {city}"
    location = geolocator.geocode(address)
    
    latitude = location.latitude if location else 0
    longitude = location.longitude if location else 0
    
    event_geohash = geohash.encode(latitude, longitude) if location else "0"
    
    dummy_event = {
        'availability': random.randint(20, 300), 
        'category': random.choice(categories),
        'city': city,
        'latitude': latitude,
        'longitude' : longitude,
        'geohash': event_geohash,
        'creatorFirstLetter': first_letter,
        'creatorId': user_id, 
        'date': random_firebase_timestamp(),
        'description': generate_event_description(event_title),
        'header': generate_event_header(),
        'imageURL': f"https://picsum.photos/id/{random.randint(1,1000)}/300/200",
        'isDisabledFriendly': random.choice([True, False]),
        'overview': generate_event_overview(),
        'price': generate_random_price(),
        'streetName': street,
        'streetNumber': str(random.randint(1, 15)),
        'title': event_title
    }
    return dummy_event

def create_dummy_user(username, password):
    user_record = auth.create_user(
        email=f'{username}@gmail.com',
        password=password
    )
    print('Successfully created new user:', user_record.uid)

    dummy_user = {
        'bookmarkedEvents': [],
        'dislikedEvents': [],
        'email': f'{username}@gmail.com',
        'homeEvents': [],
        'likedEvents': [],
        'myEvents': [],
        'publishedEvents': [],
        'savedEvents': [],
        'username': username
    }
    new_user_ref = db.collection('Users').document(user_record.uid).set(dummy_user)
    return user_record.uid, dummy_user

dummy_password = '123456'
user_ids = []
username = 'antonis7polo'
antonis_user_id, antonis_user = create_dummy_user(username, 'abc123')
user_ids.append(antonis_user_id)
username = 'nikolasbv10'
nikolas_user_id, nikolas_user = create_dummy_user(username, dummy_password)
user_ids.append(nikolas_user_id)
username = 'harrypap'
harry_user_id, harry_user = create_dummy_user(username, dummy_password)
user_ids.append(harry_user_id)
users = [antonis_user, nikolas_user, harry_user]
for _ in range(9):
    username = generate_username(1)
    dummy_user_id, dummy_user = create_dummy_user(username[0], dummy_password)
    user_ids.append(dummy_user_id)
    users.append(dummy_user)


event_count_per_city = {city: 0 for city in cities_and_streets.keys()}

if len(user_ids) >= len(cities_and_streets):
    for user_id, user, city in zip(user_ids, users, cities_and_streets.keys()):
        username = user['username']
        streets = cities_and_streets[city]
        
        print(f"User ID: {user_id} is creating events for {city}:")
        
        user_ref = db.collection('Users').document(user_id)

        for street in streets:
            event = create_dummy_event(city, street, user_id, username)

            if event_count_per_city[city] < 3:
                event_ref = db.collection('savedEvents').add(event)
                event_id = event_ref[1].id
                event['eventID'] = event_id
                new_event_ref = db.collection('savedEvents').document(event_id).set(event)
                
                user_ref.update({'savedEvents': firestore.ArrayUnion([event_id])})
                
                event_count_per_city[city] += 1
                
            else:
                event_ref = db.collection('events').add(event)
                event_id = event_ref[1].id
                event['eventID'] = event_id
                new_event_ref = db.collection('events').document(event_id).set(event)
                
                user_ref.update({'publishedEvents': firestore.ArrayUnion([event_id])})

            print(f"  Created event: {event['title']} at {street}, {city}")
else:
    print("Not enough users to cover all cities")


def update_user_attributes(user_id, all_event_ids):
    random.shuffle(all_event_ids)

    selected_event_ids = random.sample(all_event_ids, 36)

    disliked_events = selected_event_ids[:10]
    liked_events = selected_event_ids[10:24]
    bookmarked_events = selected_event_ids[24:26]
    bookmarked_and_liked_events = selected_event_ids[26:32]
    my_events_and_liked_events = selected_event_ids[32:34]
    my_events_all = selected_event_ids[34:36]

    user_ref = db.collection('Users').document(user_id)
    
    user_ref.update({
        'dislikedEvents': firestore.ArrayUnion(disliked_events),
        'likedEvents': firestore.ArrayUnion(liked_events + bookmarked_and_liked_events + my_events_and_liked_events + my_events_all),
        'bookmarkedEvents': firestore.ArrayUnion(bookmarked_events + bookmarked_and_liked_events + my_events_all),
        'myEvents': firestore.ArrayUnion(my_events_all + my_events_and_liked_events)
    })
    
def get_all_event_ids():
    event_ids = []
    events_ref = db.collection('events')

    for event_doc in events_ref.stream():
        event_ids.append(event_doc.id)
    
    return event_ids
    
all_event_ids = get_all_event_ids()
for user_id in user_ids:
    update_user_attributes(user_id, all_event_ids)

def string_price_to_float(price_str):
    if price_str.lower() == 'free':
        return 0.0
    else:
        return float(price_str.replace('$', '').replace('€', '').replace('£', ''))

def create_ticket_for_event(user_id, event_id, username, number_of_tickets, is_validated):
    event_ref = db.collection('events').document(event_id)
    event = event_ref.get()
    if event.exists:
        event_data = event.to_dict()
        price_str = event_data.get('price', '0')
        price = string_price_to_float(price_str)
        
        total_cost = price * number_of_tickets

        ticket_data = {
            'bookingDate': datetime.now(),
            'eventId': event_id,
            'fullName': username,
            'isValidated': is_validated,
            'totalCost': round(total_cost, 2),
            'totalTickets': number_of_tickets,
            'userId': user_id
        }

        db.collection('tickets').add(ticket_data)
        print(f'Ticket created for user {user_id} for event {event_id}')
        

def create_tickets_for_user_events(user_id, username):
    user_ref = db.collection('Users').document(user_id)
    user = user_ref.get()
    if user.exists:
        user_data = user.to_dict()
        my_events = user_data.get('myEvents', [])
        for event_id in my_events:
            total_tickets = random.randint(1, 3)
            for ticket_num in range(total_tickets):
                is_validated = False
                if total_tickets > 1 and ticket_num == 0:
                    is_validated = True
                number_of_tickets = random.randint(1,4)
                create_ticket_for_event(user_id, event_id, username, number_of_tickets, is_validated)
                
            print(f"Created {total_tickets} tickets for event {event_id} for user {user_id}")
            
for user_id in user_ids:
    user_ref = db.collection('Users').document(user_id)
    user_doc = user_ref.get()
    if user_doc.exists:
        user_data = user_doc.to_dict()
        username = user_data['username']
        create_tickets_for_user_events(user_id, username)
        

script_path = 'machine_learning.py'
subprocess.run(['python', script_path])
            
