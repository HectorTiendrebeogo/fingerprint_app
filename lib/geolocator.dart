import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GeolocatorScreen extends StatefulWidget {
  const GeolocatorScreen({super.key});

  @override
  State<GeolocatorScreen> createState() => _GeolocatorScreenState();
}

class _GeolocatorScreenState extends State<GeolocatorScreen> {

  static const String _kLocationServicesDisabledMessage = 'Location services are disabled.';
  static const String _kPermissionDeniedMessage = 'Permission denied.';
  static const String _kPermissionDeniedForeverMessage = 'Permission denied forever.';
  static const String _kPermissionGrantedMessage = 'Permission granted.';

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  final List<_PositionItem> _positionItems = <_PositionItem>[];
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  bool positionStreamStarted = false;


  final GlobalKey<FormState> _formKey = GlobalKey(); // Define a globale gey to manage form state


  Position? position; //Define a Potision object to get the current position
  double? distance; //Define a Distance object to get the calculate distance between two points
  late bool isStartGettingStartPosition; // boolean to know if user tap to have the start position
  late bool isStartGettingEndPosition; // boolean to know if user tap to have the end position

  /*
  Defines four controllers to get the input from the textfield
  * */
  //startLongPositionController = Start Longitude Potition Controller
  TextEditingController startLongPositionController = TextEditingController();
  TextEditingController startLatPositionController = TextEditingController();

  TextEditingController endLongPositionController = TextEditingController();
  TextEditingController endLatPositionController = TextEditingController();
  /*
  * */

  /*
  Define a function that handle for the location permission and returning the position
  * */
  Future<Position?> _getCurrentPosition() async {
    //Check for the location permission
    final hasPermission = await _handlePermission();

    if (!hasPermission) {
      //if location permission not enanle
      // open the setting
      _openLocationSettings();
      return null;
    }
    // If location is enable, get the current position
    final position = await _geolocatorPlatform.getCurrentPosition();
    if (kDebugMode) {
      print(position);
    }
    _updatePositionList(
      _PositionItemType.position,
      position.toString(),
    );
    // Return the position
    return position;
  }

  /*
  Fonction to handle for the location permission
  * */
  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (kDebugMode) {
      print(serviceEnabled);
    }
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      _updatePositionList(
        _PositionItemType.log,
        _kLocationServicesDisabledMessage,
      );

      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        _updatePositionList(
          _PositionItemType.log,
          _kPermissionDeniedMessage,
        );

        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      _updatePositionList(
        _PositionItemType.log,
        _kPermissionDeniedForeverMessage,
      );

      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    _updatePositionList(
      _PositionItemType.log,
      _kPermissionGrantedMessage,
    );
    return true;
  }

  void _updatePositionList(_PositionItemType type, String displayValue) {
    setState(() {
      _positionItems.add(_PositionItem(type, displayValue));
    });
  }

  // Function to Open the phone setting if location not enable
  void _openAppSettings() async {
    final opened = await _geolocatorPlatform.openAppSettings();
    String displayValue;

    if (opened) {
      displayValue = 'Opened Application Settings.';
    } else {
      displayValue = 'Error opening Application Settings.';
    }

    _updatePositionList(
      _PositionItemType.log,
      displayValue,
    );
  }

  //Function to open the application setting when location is not enable
  void _openLocationSettings() async {
    final opened = await _geolocatorPlatform.openLocationSettings();
    String displayValue;

    if (opened) {
      displayValue = 'Opened Location Settings';
    } else {
      displayValue = 'Error opening Location Settings';
    }

    _updatePositionList(
      _PositionItemType.log,
      displayValue,
    );
  }

  //Function to get last knowing position
  void _getLastKnownPosition() async {
    final position = await _geolocatorPlatform.getLastKnownPosition();
    if (position != null) {
      _updatePositionList(
        _PositionItemType.position,
        position.toString(),
      );
    } else {
      _updatePositionList(
        _PositionItemType.log,
        'No last known position available',
      );
    }
  }

  void _getLocationAccuracy() async {
    final status = await _geolocatorPlatform.getLocationAccuracy();
    _handleLocationAccuracyStatus(status);
  }

  void _requestTemporaryFullAccuracy() async {
    final status = await _geolocatorPlatform.requestTemporaryFullAccuracy(
      purposeKey: "TemporaryPreciseAccuracy",
    );
    _handleLocationAccuracyStatus(status);
  }

  void _handleLocationAccuracyStatus(LocationAccuracyStatus status) {
    String locationAccuracyStatusValue;
    if (status == LocationAccuracyStatus.precise) {
      locationAccuracyStatusValue = 'Precise';
    } else if (status == LocationAccuracyStatus.reduced) {
      locationAccuracyStatusValue = 'Reduced';
    } else {
      locationAccuracyStatusValue = 'Unknown';
    }
    _updatePositionList(
      _PositionItemType.log,
      '$locationAccuracyStatusValue location accuracy granted.',
    );
  }

  /*
  Fonction to calculate the distance between two points and return the distance in meters
  * */
  Future<double> _calculatEDistanceBetweenTowCoordonnate(double startLatitude, double startLongitude, double endLatitude, double endLongitude) async {
    //See the documenation to know the distance formula
    double distanceInMeters = Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude);
    return distanceInMeters;
  }



  @override
  void initState() {
    // TODO: implement initState
    isStartGettingStartPosition = false;
    isStartGettingEndPosition = false;
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Géolocalisation"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Get the current position
          position = await _getCurrentPosition();
          setState(() {

          });
        },
        label: const Text("Coordonnées",style: TextStyle(fontWeight: FontWeight.bold),),
        icon: const Icon(Icons.location_searching),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 15,right: 15,top: 15),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /*Begin current positon widget*/
              const Text("Ma coordonnées actuelle",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20)),
              const SizedBox(height: 10),
              ListTile(
                  title: const Text("Longitude",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20)),
                  //Checking if the position is not null before to print it
                  trailing: position != null ? Text("${position!.latitude}",style: const TextStyle(fontWeight: FontWeight.bold)):const SizedBox()
              ),
              const SizedBox(height: 10),
              ListTile(
                  title: const Text("Latitude",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20)),
                  //Checking if the position is not null before to print it
                  trailing: position != null ? Text("${position!.latitude}",style: const TextStyle(fontWeight: FontWeight.bold)):const SizedBox()
              ),
              const SizedBox(height: 10),
              /*End current positon widget*/
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text("Calculer la distance entre deux coordonnées", style: TextStyle(fontSize: 25),textAlign: TextAlign.center,),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Coordonnées de départ", style: TextStyle(fontSize: 20)),
                        /*When isStartGettingStartPosition == true,
                        a CircularProgessIndicator if printed to show to user that function
                        to get position is start running
                        */
                        isStartGettingStartPosition == false ? TextButton(
                            onPressed: () async {
                              setState(() {
                                isStartGettingStartPosition = true;
                              });
                              //get the position
                              Position? position = await _getCurrentPosition();
                              if(position !=  null) {
                                // When different to null, insert longitute and latitude value to the différent TextFormField
                                setState(() {
                                  startLongPositionController.text = position.longitude.toString();
                                  startLatPositionController.text = position.latitude.toString();
                                  isStartGettingStartPosition = false;
                                });
                              }
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.refresh),
                                Text("Mettre à jour", style: TextStyle()),
                              ],
                            ),
                        ) : const SizedBox(width: 15,height: 15,child: CircularProgressIndicator(),)
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.only(left: 5,right: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Theme.of(context).colorScheme.primary),
                            ),
                            child: TextFormField(
                              controller: startLongPositionController,
                              decoration: InputDecoration(
                                  hintText: "Longitude",
                                  border: InputBorder.none,
                                  prefixIcon: IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.location_history)
                                  ),
                                  suffix: IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.edit_location)
                                  ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter some text';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.only(left: 5,right: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Theme.of(context).colorScheme.primary),
                            ),
                            child: TextFormField(
                              controller: startLatPositionController,
                              decoration: InputDecoration(
                                  hintText: "Latitude",
                                  border: InputBorder.none,
                                  prefixIcon: IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.location_history)
                                  ),
                                  suffix: IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.edit_location)
                                  )
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter some text';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Coordonnées de d'arrivé", style: TextStyle(fontSize: 20)),
                        /*When isStartGettingStartPosition == true,
                        a CircularProgessIndicator if printed to show to user that function
                        to get position is start running
                        */
                        isStartGettingEndPosition == false ? TextButton(
                          onPressed: () async {
                            setState(() {
                              isStartGettingEndPosition = true;
                            });
                            Position? position = await _getCurrentPosition();
                            if(position !=  null) {
                              // When different to null, insert longitute and latitude value to the différent TextFormField
                              setState(() {
                                endLongPositionController.text = position.longitude.toString();
                                endLatPositionController.text = position.latitude.toString();
                                isStartGettingEndPosition = false;
                              });
                            }
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.refresh),
                              Text("Mettre à jour", style: TextStyle()),
                            ],
                          ),
                        ) : const SizedBox(height: 15,width: 15,child: CircularProgressIndicator())
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.only(left: 5,right: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Theme.of(context).colorScheme.primary),
                            ),
                            child: TextFormField(
                              controller: endLongPositionController,
                              decoration: InputDecoration(
                                  hintText: "Longitude",
                                  border: InputBorder.none,
                                  prefixIcon: IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.location_history)
                                  ),
                                  suffix: IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.edit_location)
                                  )
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter some text';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.only(left: 5,right: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Theme.of(context).colorScheme.primary),
                            ),
                            child: TextFormField(
                              controller: endLatPositionController,
                              decoration: InputDecoration(
                                  hintText: "Latitude",
                                  border: InputBorder.none,
                                  prefixIcon: IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.location_history)
                                  ),
                                  suffix: IconButton(
                                      onPressed: () {},
                                      icon: const Icon(Icons.edit_location)
                                  )
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter some text';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20,),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // When form state is validate, calculate the distance between the two points
                              distance = await _calculatEDistanceBetweenTowCoordonnate(
                                double.parse(startLatPositionController.text),
                                double.parse(startLongPositionController.text),
                                double.parse(endLatPositionController.text),
                                double.parse(endLongPositionController.text),
                              );
                              setState(() {
                                //Update the distance value
                              });
                            }
                          },
                          child: const Text("Calculer",style: TextStyle(fontSize: 25))
                      ),
                    ),
                    //Check if the distance different to null and show it
                    distance != null ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("La distance est de ",style: TextStyle()),
                        Text("${(distance! * 100).round() / 100} mètres ",style: TextStyle(fontSize: 15,color: Theme.of(context).colorScheme.primary)),
                      ],
                    ) : const SizedBox()
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

enum _PositionItemType {
  log,
  position,
}

class _PositionItem {
  _PositionItem(this.type, this.displayValue);

  final _PositionItemType type;
  final String displayValue;
}
