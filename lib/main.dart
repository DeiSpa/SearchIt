import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:english_words/english_words.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Search It',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 180, 232, 10)),
        ),
        home: MyHomePage(),
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

  var favorites = <WordPair>[];
  
  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;

    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Namer App'),
            leading: isDesktop
                ? null
                : Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
          ),
          drawer: isDesktop
              ? null
              : Drawer(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      DrawerHeader(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        child: Text(
                          'Namer App',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.home),
                        title: Text('Home'),
                        onTap: () {
                          setState(() {
                            selectedIndex = 0;
                          });
                          Navigator.pop(context); // Close the drawer
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.favorite),
                        title: Text('Favorites'),
                        onTap: () {
                          setState(() {
                            selectedIndex = 1;
                          });
                          Navigator.pop(context); // Close the drawer
                        },
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
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.favorite),
                        label: Text('Favorites'),
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

class GeneratorPage extends StatefulWidget {
  @override
  _GeneratorPageState createState() => _GeneratorPageState();
}
Random random = Random();

class _GeneratorPageState extends State<GeneratorPage> {
  final TextEditingController _controller = TextEditingController();
  String? searchQuery;
  List<String> imageUrls = [];
  bool isLoading = false;
  int numb = random.nextInt(15);

  Future<void> fetchImages(String query) async {
    setState(() {
      isLoading = true;
      imageUrls = [];
    });

    const apiKey = '4FNTqjMqrJBJjmgxCOIpSjYjJmHq6SFEmhlZe8T6x5KQaU7CGOSz32us';
    int randomPage = Random().nextInt(15) + 1;
    final url = Uri.parse('https://api.pexels.com/v1/search?query=$query&page=$randomPage&per_page=10');

    try {
      final response = await http.get(url, headers: {
        'Authorization': apiKey,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = data['photos'];

        setState(() {
           imageUrls = photos.map<String>((photo) => photo['src']['medium'].toString()).toList();
        });
        print('Fetched images: $imageUrls'); // Debug print to verify URLs
      } else {
        print("Error fetching images: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching images: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon = appState.favorites.contains(pair) ? Icons.favorite : Icons.favorite_border;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search for an image...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (text) {
                setState(() {
                  searchQuery = text.toLowerCase();
                });
                fetchImages(searchQuery!);
              },
            ),
          ),
          SizedBox(height: 10),
          if (isLoading)
            CircularProgressIndicator()
          else if (imageUrls.isNotEmpty)
            // Carousel of images
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    imageUrls[index],
                    height: 300,
                    width: 300,
                    fit: BoxFit.cover,
                  );
                },
              ),
            )
          else if (searchQuery == null)
            Text(
              'Welcome, search for a word!',
              style: Theme.of(context).textTheme.headlineSmall,
            )
          else
            BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
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

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
          ),
      ],
    );
  }
}
