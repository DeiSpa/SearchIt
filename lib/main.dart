// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: true,
        title: 'TEACCH',
        theme: ThemeData(
          useMaterial3: false,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 72, 0, 255)),
        ),
        home: const LicenseValidationScreen(),
      ),
    );
  }
}

class LicenseValidationScreen extends StatefulWidget {
  const LicenseValidationScreen({Key? key}) : super(key: key);

  @override
  _LicenseValidationScreenState createState() =>
      _LicenseValidationScreenState();
}

class _LicenseValidationScreenState extends State<LicenseValidationScreen> {
  @override
  void initState() {
    super.initState();
    _checkStoredLicense();
  }

  Future<void> _checkStoredLicense() async {
     final storedLicenseKey = await storage.read(key: 'licenseKey');
    if (storedLicenseKey == "License_is_OK") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()),
        );
    }
  }


  final TextEditingController _licenseController = TextEditingController();
  String? _errorMessage;

  Future<bool> validateLicense(String licenseKey) async {
    final url = Uri.parse('https://api.jsonbin.io/v3/b/6750e2c3ad19ca34f8d5bb8f');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final licenses = decodedResponse['record']['licenses'] as List;
        final matchingLicense = licenses.firstWhere(
          (license) => license['key'] == licenseKey,
          orElse: () => null,
        );

        if (matchingLicense != null && matchingLicense['status'] == 'active') {
          await storage.write(key: 'licenseKey', value: "License_is_OK");
          return true;
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: Could not connect to server.';
      });
    }
    return false;
  }

  void _onValidatePressed() async {
    final licenseKey = _licenseController.text.trim();
    if (licenseKey.isEmpty) {
      setState(() {
        _errorMessage = 'License key cannot be empty.';
      });
      return;
    }

    final isValid = await validateLicense(licenseKey);
    if (isValid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage()),
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid or inactive license key.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('License Validation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter your license key to continue:',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _licenseController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'License Key',
                errorText: _errorMessage,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onValidatePressed,
              child: const Text('Validate License'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

//
//
//  NAVIGATION BAR AND MENU
//
//

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;

    switch (selectedIndex) {
      case 0:
        page = const GeneratorPage();
        break;
      // case 1:
      //   page = const SettingsPage();
      //   break;
      case 1:
        page = const GuidePage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('TEACCH'),
            leading: isDesktop
                ? null
                : Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
            /*actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                },
              ),
            ],*/
          ),
          drawer: isDesktop
            ? null
            : Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      height: 100,
                      color: Theme.of(context).colorScheme.primary,
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          'TEACCH',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),

                    // Home button
                    ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text('Αρχική'),
                      onTap: () {
                        setState(() {
                          selectedIndex = 0;
                        });
                        Navigator.pop(context); // Close the drawer
                      },
                    ),

                    // Favorites button
                    // ListTile(
                    //   leading: const Icon(Icons.settings),
                    //   title: const Text('Ρυθμίσεις'),
                    //   onTap: () {
                    //     setState(() {
                    //       selectedIndex = 1;
                    //     });
                    //     Navigator.pop(context); // Close the drawer
                    //   },
                    // ),

                    // Guide page button
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text('Οδηγίες χρήσης'),
                      onTap: () {
                        setState(() {
                          selectedIndex = 1;
                        });
                        Navigator.pop(context); // Close the drawer
                      },
                    ),

                    // Company name
                    Container(
                      height: 500,
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'By 1c3Gh3tt0',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          body: Row(
            children: [
              if (isDesktop)
                SafeArea(
                  child: NavigationRail(
                    extended: true,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home),
                        label: Text('Αρχική'),
                      ),
                      // NavigationRailDestination(
                      //   icon: Icon(Icons.settings),
                      //   label: Text('Ρυθμίσεις'),
                      // ),
                      NavigationRailDestination(
                        icon: Icon(Icons.help),
                        label: Text('Οδηγίες χρήσης'),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

//
//
//  API HANDLER
//
//

class FullscreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullscreenImagePage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 125, 115, 115),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color.fromARGB(255, 193, 177, 233),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5, // Allow zooming out
          maxScale: 5.0, // Allow zooming in
          child: FittedBox(
            fit: BoxFit.contain, // Adjust to show the full image, or use BoxFit.cover for cropping
            child: Image.network(
              imageUrl,
              width: MediaQuery.of(context).size.width * 1, // Scale up the width
              height: MediaQuery.of(context).size.height * 1, // Scale up the height
            ),
          ),
        ),
      ),
    );
  }
}


class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _GeneratorPageState createState() => _GeneratorPageState();
}
Random random = Random();

class _GeneratorPageState extends State<GeneratorPage> {
  final TextEditingController _controller = TextEditingController();
  String? searchQuery;
  List<String> imageUrls = [];
  List<String?> imageDescriptions = [];
  List<String> queryList = [];
  bool isLoading = false;
  int currentImage = 0;
  final PageController _pageController = PageController();

  Future<String> translateToGreek(String text) async {
    String deepLApiKey = await fetchApiKey();
    print(deepLApiKey);
    final url = Uri.parse('https://api-free.deepl.com/v2/translate');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'DeepL-Auth-Key $deepLApiKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'text': text,
          'source_lang': 'EL',
          'target_lang': 'EN', // Greek language code for DeepL
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translations'][0]['text'];
      } else {
        throw Exception('Failed to translate text: ${response.statusCode}');
      }
    } catch (e) {
      print("Error translating text: $e");
      return "Translation error";
    }
  }

  // When user searches for a word, fetch the image
  Future<void> fetchImage(String query, String? original) async {
    const apiKey = '4FNTqjMqrJBJjmgxCOIpSjYjJmHq6SFEmhlZe8T6x5KQaU7CGOSz32us';
    int randomPage = Random().nextInt(30) + 1;
    final url = Uri.parse('https://api.pexels.com/v1/search?query=$query&page=$randomPage&per_page=1');
    
    try {
      final response = await http.get(url, headers: {
        'Authorization': apiKey,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = data['photos'];

        if (photos.isNotEmpty) {
          setState(() {
            imageUrls.add(photos[0]['src']['medium'].toString());
            imageDescriptions.add(original);
            queryList.add(query);
          });
        } else {
          print("No images found for query: $original");
        }
      } else {
        print("Error fetching image: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching image: $e");
    }
  }

  // When user clicks refresh, fetch new image
  Future<void> fetchNewImage(int index) async {
    String query = queryList[index];

    const apiKey = '4FNTqjMqrJBJjmgxCOIpSjYjJmHq6SFEmhlZe8T6x5KQaU7CGOSz32us';
    int randomPage = Random().nextInt(30) + 1; // Random page number for diversity
    final url = Uri.parse('https://api.pexels.com/v1/search?query=$query&page=$randomPage&per_page=1');

    try {
      final response = await http.get(url, headers: {
        'Authorization': apiKey,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = data['photos'];

        if (photos.isNotEmpty) {
          setState(() {
            imageUrls[index] = photos[0]['src']['medium'].toString();
          });
        }
      }
    } catch (e) {
      print("Error fetching image: $e");
      
    }
  }

  //
  //
  //  HOME PAGE
  //
  //

  @override
  Widget build(BuildContext context) {
    //
    //
    //  SEARCH BAR
    //
    //

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ψάξε μία εικόνα εδώ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),

              onSubmitted: (text) async {
                if (text.trim().isNotEmpty) {
                  setState(() {
                    searchQuery = text.trim().toLowerCase();

                  });
                  String translatedQuery = await translateToGreek(searchQuery!);
                  
                  fetchImage(translatedQuery, searchQuery);
                  _controller.clear();
                }
              },
            ),
          ),

          //
          //
          //  IMAGES CAROUSEL
          //
          //
          
          const SizedBox(height: 20),
          if (isLoading)
            const CircularProgressIndicator()
          else if (imageUrls.isNotEmpty)
            SizedBox(
              height: 320,
              width: 320,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentImage = index;
                  });
                },
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: Stack(
                      children: [
                        // Displaying the image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30.0),
                          child: Image.network(
                            imageUrls[index],
                            height: 320,
                            width: 320,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Refresh button
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                fetchNewImage(currentImage);
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                             child: IconButton(
                              icon: const Icon(
                                Icons.fullscreen,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FullscreenImagePage(imageUrl: imageUrls[index]),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 135,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                             child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  imageUrls.removeAt(index);
                                  imageDescriptions.removeAt(index);
                                  if (currentImage >= imageUrls.length) {
                                    currentImage = imageUrls.isEmpty ? 0 : imageUrls.length - 1;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else if (searchQuery == null)
            Text(
              'Καλωσήρθες!',
              style: Theme.of(context).textTheme.headlineSmall,
            )
          else
            Text(
              'Ψάχνω...',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

          //
          //
          //  BUTTONS FOR PREVIOUS AND NEXT IMAGE
          //
          //
          
          const SizedBox(height: 10),
          if (imageUrls.isNotEmpty) 
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (currentImage > 0) {
                      setState(() {
                        currentImage -= 1;
                      });
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: const Text('<'),
                ),
                const SizedBox(width: 10),
                Text(
                  imageDescriptions.isNotEmpty && currentImage < imageDescriptions.length
                      ? 'Έψαξες: ${imageDescriptions[currentImage]}'
                      : '',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (currentImage < imageUrls.length - 1) {
                      setState(() {
                        currentImage += 1;
                      });
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: const Text('>'),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Text(pair.asLowerCase, style: style),
      ),
    );
  }
}

//
//
//  SETTINGS PAGE
//
//

// class SettingsPage extends StatefulWidget {
//   const SettingsPage({Key? key}) : super(key: key);

//   @override
//   // ignore: library_private_types_in_public_api
//   _SettingsPageState createState() => _SettingsPageState();
// }

// class _SettingsPageState extends State<SettingsPage> {
//   bool isAudioMuted = false;
//   bool isSearchFilterEnabled = false;
//   int searchResultsCount = 1;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).colorScheme.primaryContainer,
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Ρυθμίσεις',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const Divider(),
//             const SizedBox(height: 20),
            
//             // Audio settings section
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Ήχος εφαρμογής',
//                   style: TextStyle(fontSize: 20),
//                 ),
//                 Switch(
//                   value: isAudioMuted,
//                   onChanged: (bool value) {
//                     setState(() {
//                       isAudioMuted = value;
//                     });
//                   },
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 5),

//             // Search filter section
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Φίλτρο αναζήτησης',
//                   style: TextStyle(fontSize: 20),
//                 ),
//                 Switch(
//                   value: isSearchFilterEnabled,
//                   onChanged: (bool value) {
//                     setState(() {
//                       isSearchFilterEnabled = value;
//                     });
//                   },
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 5),

//             // Results per search section
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Αποτελέσματα αναζήτησης',
//                   style: TextStyle(fontSize: 20),
//                 ),
//                 DropdownButton<int>(
//                   value: searchResultsCount,
//                   items: List.generate(
//                     5,
//                     (index) => DropdownMenuItem<int>(
//                       value: index + 1,
//                       child: Text((index + 1).toString()),
//                     ),
//                   ),
//                   onChanged: (int? newValue) {
//                     setState(() {
//                       searchResultsCount = newValue ?? 1;
//                     });
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//
//
//  GUIDE PAGE
//
//

class GuidePage extends StatelessWidget {
  const GuidePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Οδηγίες Χρήσης',
              style: TextStyle(fontSize: 24),
            ),
            Divider(),

            // Search Icon Section
            SizedBox(height: 20),
            Text(
              'Μπάρα αναζήτησης',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '1. Άγγιξε την μπάρα',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              '2. Πληκτρολόγησε μία λέξη',
              style: TextStyle(fontSize: 18),
            ),
            Row(
              children: [
                Text(
                  '3. Πάτησε το ',
                  style: TextStyle(fontSize: 18),
                ),
                Icon(Icons.keyboard_return, size: 24), // Enter icon
              ],
            ),
            Text(
              '4. Έτοιμο!',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              '5. Επανέλαβε για περισσότερες λέξεις',
              style: TextStyle(fontSize: 18),
            ),
            Divider(),
            
            // Camera Icon Section
            SizedBox(height: 20),
            Text(
              'Αποτελέσματα αναζήτησης',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '1. Το αποτέλεσμα της πρώτης αναζήτησης, είναι η πρώτη φωτογραφία',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              '2. Αν δεν είναι το αποτέλεσμα που περίμενες πάτησε το κουμπί πάνω αριστερά στην φωτογραφία',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              '3. Για την μετάβαση σε άλλα αποτελέσματα χρησιμοποίησε τα κουμπιά ( < ) και ( > ).',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> fetchApiKey() async {
  const url = 'https://api.jsonbin.io/v3/b/67519301ad19ca34f8d604bc'; // Replace with your JSONBin URL
  const headers = {
    'X-Master-Key': r"$2a$10$Xknc5ZVPjofBAWhTPU/RduCR3AmnMEZkLgPE8Ztb12OUv06nDewCi"// Replace with your JSONBin Master Key
  };

  try {
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data['record']['DeepLApiKey']) ;
      return data['record']['DeepLApiKey']; // Adjust based on your JSON structure
    } else {
      throw Exception('Failed to fetch API key. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching API key: $e');
    throw Exception('Could not fetch API key.');
  }
}