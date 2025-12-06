import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  MobileAds.instance.initialize();
  runApp(const CashVaultApp());
}

class CashVaultApp extends StatelessWidget {
  const CashVaultApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CashVault',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.amber,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int coins = 0;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadCoins();
    _loadAds();
  }

  void _loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      coins = prefs.getInt('coins') ?? 0;
    });
  }

  void _saveCoins() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('coins', coins);
  }

  void _loadAds() {
    // TEST IDS — replace with your real ones later
    BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _bannerAd = ad as BannerAd),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();

    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    );
  }

  void _showInterstitial() {
    _interstitialAd?.show();
    _interstitialAd = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CashVault', style: TextStyle(color: Colors.amber)),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '$coins Coins',
              style: const TextStyle(fontSize: 42, color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ),
          if (_bannerAd != null)
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          Expanded(
            child: ListView(
              children: [
                OfferCard(
                  title: "AdGem Offers",
                  url: "https://wall.adgem.com/v1?appid=12345&playerid=test123",
                  reward: 500,
                  onComplete: () => setState(() => coins += 500),
                ),
                OfferCard(
                  title: "CPX Research Surveys",
                  url: "https://cpx-research.com/index.php?app=12345&userid=test123",
                  reward: 800,
                  onComplete: () => setState(() => coins += 800),
                ),
                OfferCard(
                  title: "OfferToro Games",
                  url: "https://www.offertoro.com/ifr/show/12345/test123/12345",
                  reward: 1200,
                  onComplete: () => setState(() => coins += 1200),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        child: const Icon(Icons.attach_money, color: Colors.black),
        onPressed: () {
          if (coins >= 5000) {
            // In real app: send payout request
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PayPal $5 payout requested!')),
            );
            setState(() => coins -= 5000);
            _saveCoins();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Need ${5000 - coins} more coins for $5 PayPal')),
            );
          }
        },
      ),
    );
  }
}

class OfferCard extends StatelessWidget {
  final String title;
  final String url;
  final int reward;
  final VoidCallback onComplete;

  const OfferCard({super.key, required this.title, required this.url, required this.reward, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      color: Colors.grey[900],
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.amber)),
        subtitle: Text("Earn $reward coins"),
        trailing: const Icon(Icons.arrow_forward, color: Colors.amber),
        onTap: () async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            // In real app: verify completion via server callback
            // For demo: just give coins
            onComplete();
          }
        },
      ),
    );
  }
}
