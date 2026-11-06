import 'dart:io';
import 'services/voice_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/products_screen.dart';
import 'screens/shop_registration_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/history_screen.dart';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'services/dashboard_service.dart';
void main() {
  runApp(const SovereignLedgerApp());
}

const Color primaryGreen = Color(0xFF16834A);
const Color lightGreen = Color(0xFFE8F5EC);
const Color backgroundColor = Color(0xFFF7F9F7);
const Color darkText = Color(0xFF17251C);
const Color secondaryText = Color(0xFF78847B);

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  bool _isLoading = true;
  int? _shopId;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final savedShopId = prefs.getInt('shop_id');

    if (!mounted) return;

    setState(() {
      _shopId = savedShopId;
      _isLoading = false;
    });
  }

  void _onShopRegistered(int shopId) {
    setState(() {
      _shopId = shopId;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: primaryGreen,
          ),
        ),
      );
    }

    if (_shopId != null) {
      return const MainNavigation();
    }

    return ShopRegistrationScreen(
      onRegistered: (shopId) async {
        _onShopRegistered(shopId);
      },
    );
  }
}
class SovereignLedgerApp extends StatelessWidget {
  const SovereignLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sovereign Voice Ledger',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
        ),
        fontFamily: 'Roboto',
      ),
      home: const AppStartupGate(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    CustomersScreen(),
    ProductsScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: screens[selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: lightGreen,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: primaryGreen),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: primaryGreen),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: primaryGreen),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history, color: primaryGreen),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DashboardService _dashboardService = DashboardService();

  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final data = await _dashboardService.fetchDashboard();

      if (!mounted) return;

      setState(() {
        dashboardData = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year} '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDashboardContent() {
    final data = dashboardData!;

    final recentTransactions =
        (data['recent_transactions'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.storefront,
                color: primaryGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sovereign Ledger',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Your shop, your accounts',
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh, size: 25),
            ),
          ],
        ),

        const SizedBox(height: 28),

        const Text(
          'Your Dashboard',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          "Here's what's happening with your shop.",
          style: TextStyle(
            color: secondaryText,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'TOTAL OUTSTANDING',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _formatCurrency(data['total_outstanding']),
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Amount customers owe your shop',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Customer balances',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people_outline,
                title: 'Customers',
                value: '${data['total_customers'] ?? 0}',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                icon: Icons.receipt_long_outlined,
                title: 'Transactions',
                value: '${data['total_transactions'] ?? 0}',
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        const Text(
          "Today's Activity",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),

        const SizedBox(height: 13),

        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.shopping_cart_outlined,
                title: 'Daily Sales',
                value: _formatCurrency(data['daily_sales']),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                icon: Icons.payments_outlined,
                title: 'Collections',
                value: _formatCurrency(data['daily_collections']),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        const Text(
          'Quick transaction',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),

        const SizedBox(height: 13),

        InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VoiceScreen(),
              ),
            );

            if (mounted) {
              _loadDashboard();
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 23),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryGreen.withOpacity(0.2),
              ),
            ),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: primaryGreen,
                  child: Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Record a transaction',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Speak to record a purchase or repayment',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent transactions',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'See all',
                style: TextStyle(color: primaryGreen),
              ),
            ),
          ],
        ),

        if (recentTransactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No transactions recorded yet.',
                style: TextStyle(color: secondaryText),
              ),
            ),
          )
        else
          ...recentTransactions.map((item) {
            final transaction =
                item as Map<String, dynamic>;

            final type =
                transaction['transaction_type']
                    ?.toString()
                    .toLowerCase() ?? '';

            final isPurchase = type == 'purchase';

            return _TransactionTile(
              name: transaction['customer_name']?.toString()
                      ?? 'Customer',
              description: isPurchase
                  ? 'Purchase'
                  : 'Repayment',
              amount: _formatCurrency(
                transaction['total_amount'],
              ),
              time: _formatDate(
                transaction['created_at'],
              ),
              icon: isPurchase
                  ? Icons.shopping_bag_outlined
                  : Icons.payments_outlined,
              isPurchase: isPurchase,
            );
          }),

        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && dashboardData == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryGreen,
        ),
      );
    }

    if (errorMessage != null && dashboardData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 55,
                color: secondaryText,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loadDashboard,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: _buildDashboardContent(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 25),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String name;
  final String description;
  final String amount;
  final String time;
  final IconData icon;
  final bool isPurchase;

  const _TransactionTile({
    required this.name,
    required this.description,
    required this.amount,
    required this.time,
    required this.icon,
    required this.isPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: lightGreen,
            child: Icon(icon, color: primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPurchase ? Colors.red.shade700 : primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderScreen({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 65, color: primaryGreen),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final VoiceService _voiceService = VoiceService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlayingResponse = false;

  String? serverStatus;
  String? serverMessage;

  String selectedLanguageCode = 'en-IN';

  bool isRecording = false;
  bool isProcessing = false;

  String? recordedFilePath;
  String? errorMessage;

  Future<void> _startRecording() async {
    try {
      setState(() {
        isProcessing = true;
        errorMessage = null;
        recordedFilePath = null;
      });

      final hasPermission = await _audioRecorder.hasPermission();

      if (!hasPermission) {
        if (!mounted) return;

        setState(() {
          errorMessage = 'Microphone permission was denied.';
          isProcessing = false;
        });
        return;
      }

      final directory = await getTemporaryDirectory();

      final filePath =
          '${directory.path}/voice_transaction_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: filePath,
      );

      if (!mounted) return;

      setState(() {
        isRecording = true;
        isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
        errorMessage = 'Unable to start recording: $e';
      });
    }
  }

Future<void> _playBackendResponse(
  Map<String, dynamic> response,
) async {
  final audioBase64 = response['audio_base64'];

  if (audioBase64 is! String || audioBase64.isEmpty) {
    return;
  }

  final audioBytes = base64Decode(audioBase64);
  final directory = await getTemporaryDirectory();

  final audioPath =
      '${directory.path}/voice_response_${DateTime.now().millisecondsSinceEpoch}.wav';

  final audioFile = File(audioPath);
  await audioFile.writeAsBytes(audioBytes, flush: true);

  if (!mounted) return;

  setState(() {
    isPlayingResponse = true;
  });

  try {
    final playbackComplete = _audioPlayer.onPlayerComplete.first;

    await _audioPlayer.play(
      DeviceFileSource(audioPath),
    );

    await playbackComplete;
  } finally {
    if (mounted) {
      setState(() {
        isPlayingResponse = false;
      });
    }
  }
}

Future<void> _stopRecording() async {
  try {
    setState(() {
      isProcessing = true;
      errorMessage = null;
      serverStatus = null;
      serverMessage = null;
    });

    final path = await _audioRecorder.stop();

    if (path == null) {
      throw Exception('Recording file was not created.');
    }

    if (!mounted) return;

    setState(() {
      isRecording = false;
      recordedFilePath = path;
    });

    final response = await _voiceService.sendAudio(
      audioPath: path,
      languageCode: selectedLanguageCode,
    );

    if (!mounted) return;

    setState(() {
      serverStatus = response['status']?.toString();
      serverMessage = response['message']?.toString();
    });

    await _playBackendResponse(response);

    if (!mounted) return;

    setState(() {
      isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Backend response: ${serverStatus ?? 'Received'}',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isRecording = false;
      isProcessing = false;
      isPlayingResponse = false;
      errorMessage = 'Voice request failed: $e';
    });
  }
}

  Future<void> _handleMicrophoneTap() async {
    if (isProcessing) return;

    if (isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

@override
void dispose() {
  _audioRecorder.dispose();
  _audioPlayer.dispose();
  super.dispose();
}
  Widget _buildLanguageButton({
    required String label,
    required String languageCode,
  }) {
    final bool isSelected =
        selectedLanguageCode == languageCode;

    return GestureDetector(
      onTap: isRecording || isProcessing
          ? null
          : () {
              setState(() {
                selectedLanguageCode = languageCode;
              });
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryGreen,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : primaryGreen,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Voice Transaction'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'What would you like to record?',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              const Text(
                'Choose your language',
                style: TextStyle(
                  fontSize: 15,
                  color: secondaryText,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildLanguageButton(
                      label: 'English',
                      languageCode: 'en-IN',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLanguageButton(
                      label: 'தமிழ்',
                      languageCode: 'ta-IN',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 45),

              GestureDetector(
                onTap: _handleMicrophoneTap,
                child: CircleAvatar(
                  radius: 65,
                  backgroundColor:
                      isRecording ? Colors.red : primaryGreen,
                  child: isProcessing
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Icon(
                          isRecording ? Icons.stop : Icons.mic,
                          size: 65,
                          color: Colors.white,
                        ),
                ),
              ),

              const SizedBox(height: 25),

              Text(
                isPlayingResponse
                    ? 'Assistant is speaking...'
                    : isProcessing
                        ? 'Processing your request...'
                    : isRecording
                        ? 'Recording in progress...'
                        : 'Tap the microphone to start',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isRecording ? Colors.red : secondaryText,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                isRecording
                    ? 'Tap the red button to stop recording'
                    : 'Speak your purchase or repayment',
                style: const TextStyle(
                  fontSize: 12,
                  color: secondaryText,
                ),
                textAlign: TextAlign.center,
              ),

              if (recordedFilePath != null) ...[
                const SizedBox(height: 25),

                const Icon(
                  Icons.check_circle,
                  color: primaryGreen,
                  size: 28,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Audio recorded successfully',
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Audio has been sent to the backend.',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              if (serverStatus != null) ...[
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primaryGreen.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Backend Response',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: darkText,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Status: $serverStatus',
                        style: const TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (serverMessage != null &&
                          serverMessage!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          serverMessage!,
                          style: const TextStyle(
                            color: secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              if (errorMessage != null) ...[
                const SizedBox(height: 20),

                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
