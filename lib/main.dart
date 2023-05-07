import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String currentAddress = 'My Address';
  Position? currentposition;
  InAppWebViewController? webViewController;


  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Please enable Your Location Service');
      return null; // Return null if location service is not enabled
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location permissions are denied');
        return null; // Return null if location permissions are denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg:
          'Location permissions are permanently denied, we cannot request permissions.');
      return null; // Return null if location permissions are permanently denied
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];

      setState(() {
        currentposition = position;
        currentAddress =
        "${place.locality}, ${place.postalCode}, ${place.country}";
      });

      return position; // Return the obtained position
    } catch (e) {
      print(e);
      return null; // Return null if any error occurs
    }
  }

  Future<void> sendDataToMockApi(Map<String, dynamic> data) async {
    final url =
    Uri.parse('https://638ebb4b9cbdb0dbe31369c0.mockapi.io/location');

    final response = await http.post(
      url,
      body: data,
    );

    if (response.statusCode == 201) {
      print('Data sent successfully!');
    } else {
      print('Failed to send data. Error: ${response.statusCode}');
    }
  }
  Future<void> fetchIdFromMockApi() async {
    final url = Uri.parse('https://638ebb4b9cbdb0dbe31369c0.mockapi.io/location');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseBody = response.body;
      final data = json.decode(responseBody);

      // Extract the ID field from the data
      final id = data['id'];

      // Use the retrieved ID
      print('ID: $id');
    } else {
      print('Failed to fetch data. Error: ${response.statusCode}');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Location',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currentAddress,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              currentposition != null
                  ? Text(
                'Latitude = ${currentposition?.latitude}',
                style: TextStyle(
                  fontSize: 16,
                ),
              )
                  : Container(),
              currentposition != null
                  ? Text(
                'Longitude = ${currentposition?.longitude}',
                style: TextStyle(
                  fontSize: 16,
                ),
              )
                  : Container(),
              SizedBox(height: 20), // Add spacing between the text and button
              ElevatedButton(
                onPressed: () async {
                  await _determinePosition();

                  final currentposition = this.currentposition;
                  if (currentposition != null) {
                    final dataToSend = {
                      'location': currentAddress,
                      'latitude': currentposition.latitude.toString(),
                      'longitude': currentposition.longitude.toString(),
                    };

                    await sendDataToMockApi(dataToSend);
                  }
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Locate me',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}