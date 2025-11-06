const airportData = {
  "JFK": {
    "name": "John F. Kennedy International Airport",
    "taxiways": ["A", "B", "C", "B1", "C2"],
    "segments": {
      "A": [
        [40.6413, -73.7781],
        [40.6420, -73.7790],
      ],
      "B": [
        [40.6413, -73.7781],
        [40.6430, -73.7800],
      ],
    },
    "intersections": {
      "A": {
        "B": [40.6413, -73.7781],
        "C": [40.6420, -73.7790],
      },
      "B": {
        "A": [40.6413, -73.7781],
        "C": [40.6430, -73.7800],
      },
    },
  },
  "LAX": {
    "name": "Los Angeles International Airport",
    "taxiways": ["D", "E", "F", "G1", "H2"],
    // ...
  },
};
