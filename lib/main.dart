import 'package:fingerprint_app/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            primary: Colors.orange,
            onPrimary: Colors.white,
            secondary: Colors.grey,
            tertiary: Colors.black,
            onTertiary: Colors.white
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum _SupportState {
  unknown,
  supported,
  unsupported,
}

class _MyHomePageState extends State<MyHomePage> {
  //
  final LocalAuthentication authentication = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  bool? _canCheckBiometrics;
  List<BiometricType>? _availableBiometrics;
  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;
  bool _authenticated = false;

  /*
  Check if or not the device hardware have a biométrics authentication
  * */
  Future<void> _checkBiometrics() async {
    late bool canCheckBiometrics;
    try {
      canCheckBiometrics = await authentication.canCheckBiometrics;
    } on PlatformException catch (e) {
      canCheckBiometrics = false;
      if (kDebugMode) {
        print(e);
      }
    }
    if (!mounted) {
      return;
    }
    if (kDebugMode) {
      print(_canCheckBiometrics);
    }
    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });
  }

  /*

  */

  Future<void> _getAvailableBiometrics() async {
    late List<BiometricType> availableBiometrics;
    try {
      availableBiometrics = await authentication.getAvailableBiometrics();
    } on PlatformException catch (e) {
      availableBiometrics = <BiometricType>[];
      if (kDebugMode) {
        print(e);
      }
    }
    if (!mounted) {
      return;
    }
    if (kDebugMode) {
      print(availableBiometrics);
    }
    setState(() {
      _availableBiometrics = availableBiometrics;
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      authenticated = await authentication.authenticate(
        localizedReason:
        'Scan your fingerprint (or face or whatever) to authenticate',
        options: const AuthenticationOptions(
          useErrorDialogs: false,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Authenticating';
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error - ${e.message}';
      });
      return;
    }
    if (!mounted) {
      return;
    }

    final String message = authenticated ? 'Authorized' : 'Not Authorized';
    setState(() {
      _authorized = message;
      _authenticated = authenticated;
    });
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        dismissDirection: DismissDirection.up,
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    authentication.isDeviceSupported().then(
          (bool isSupported) => setState(() => _supportState = isSupported
          ? _SupportState.supported
          : _SupportState.unsupported),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Authentication"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("S'authentifier pour utiliser les services de géolocalisation",style: TextStyle(fontSize: 20),textAlign: TextAlign.center,),
              const SizedBox(height: 50),
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
                      await _checkBiometrics();
                      if (_canCheckBiometrics == true) {
                        await _getAvailableBiometrics();
                        if (_availableBiometrics!.isNotEmpty) {
                          await _authenticateWithBiometrics();
                          if (_authenticated == true) {
                            if (context.mounted) {
                              _showMessage(context,"Authentification réussi");
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>const GeolocatorScreen()));
                            }
                          }
                        }
                      }
                    },
                    child: const Text("S'authentifier",style: TextStyle(fontSize: 25))
                ),
              )
              /*ListTile(
                title: const Text("Authentifation biométric",style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text( _canCheckBiometrics == true ? "Disponible" : "Non disponible",style: const TextStyle()),
              ),
              _availableBiometrics != null ? Expanded(
                child: ListView.separated(
                    itemBuilder: (context,index) {
                      return ListTile(
                        title: Text(_availableBiometrics![index].name,style: const TextStyle(fontWeight: FontWeight.bold)),
                        //trailing: Text( _canCheckBiometrics == true ? "Disponible" : "Non disponible",style: const TextStyle()),
                      );
                    },
                    separatorBuilder: (context,index) {
                      return const Divider();
                    },
                    itemCount: _availableBiometrics!.length
                ),
              ) : const SizedBox()*/
            ],
          ),
        ),
      ),
      /*bottomNavigationBar: SizedBox(
        height: 70,
        child: BottomAppBar(
          color: Theme.of(context).colorScheme.surface,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            ),
              onPressed: () async {
                await _checkBiometrics();
                if (_canCheckBiometrics == true) {
                  await _getAvailableBiometrics();
                  if (_availableBiometrics!.isNotEmpty) {
                    await _authenticateWithBiometrics();
                    if (_authenticated == true) {
                      _showMessage(context,"Authentification réussi");
                    }
                  }
                }
              },
              child: const Text("Empreinte digitale",style: TextStyle(fontSize: 25))
          ),
        ),
      )*/
    );
  }
}
