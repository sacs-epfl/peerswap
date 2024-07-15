import json

import requests

def get_json(url):

    response = requests.get(url).json()
    with open("latencies.json", "w") as latencies_file:
        json.dump(response, latencies_file)


invalid_cities = [41, 43, 101, 120, 121, 134, 146, 152, 159, 160, 164, 172, 173, 178, 179, 183, 198, 199, 207, 219,
                  220, 224, 253, 255, 257, 262, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277,
                  278, 279, 280, 281, 282]
cities = ["%d" % i for i in range(1, 283) if i not in invalid_cities]
cities_str = ",".join(cities)
# url = "https://wondernetwork.com/ping-data?sources=%s&destinations=%s" % (cities_str, cities_str)
#get_json(url)

with open("latencies.json", "r") as latencies_file:
    latencies_json = json.load(latencies_file)
ping_data = latencies_json["pingData"]

with open("latencies.txt", "w") as out_file:
    for from_city in cities:
        from_city_id: int = int(from_city)
        print("Analyzing city %d" % from_city_id)
        from_data = ping_data[from_city]
        avg_latencies = []
        for to_city in cities:
            to_data = from_data[to_city]
            print(to_data)
            avg_latency: float = float(to_data['avg']) / 2 if to_data['avg'] else 10
            assert avg_latency >= 0
            avg_latencies.append(avg_latency)

        out_file.write("%s\n" % ",".join(["%g" % l for l in avg_latencies]))
