import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

double walletBalance = 15890.74;

class FraudLog {
  final String reason;
  final int riskScore;
  final String time;

  FraudLog({
    required this.reason,
    required this.riskScore,
    required this.time,
  });
}

/// GLOBAL LIST
List<FraudLog> fraudHistory = [];

void main() {
  runApp(const SentryPayApp());
}

class SentryPayApp extends StatelessWidget {
  const SentryPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SentryPay',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const DashboardPage(),
    );
  }
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {

  bool isScanned = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [

          /// CAMERA
          MobileScanner(
            onDetect: (BarcodeCapture capture) {

              if (isScanned) return;
              isScanned = true;

              for (final barcode in capture.barcodes) {

                final String? code = barcode.rawValue;

                if (code != null) {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnalysisPage(qrData: code),
                    ),
                  );

                  break;
                }
              }
            },
          ),

          /// DARK OVERLAY
          Container(
            color: Colors.black.withOpacity(0.6),
          ),

          /// SCAN BOX
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          /// TEXT
          const Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Text(
              "Scan QR Code",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Text(
              "Align QR within the frame",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisPage extends StatefulWidget {
  final String qrData;

  const AnalysisPage({super.key, required this.qrData});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {

  int riskScore = 0;
  String riskLevel = "";
  Color riskColor = Colors.green;
  String riskReason = "";

  @override
  void initState() {
    super.initState();
    analyzeQR();
  }

  void analyzeQR() async {

    await Future.delayed(const Duration(seconds: 2));

    /// Extract risk from QR
    final uri = Uri.tryParse(widget.qrData);
    final riskValue = uri?.queryParameters['risk'];

    riskScore = int.tryParse(riskValue ?? "10") ?? 10;

    /// Generate explanation
    riskReason = getRiskReason(widget.qrData, riskScore);

    /// Decide level
    if (riskScore > 75) {
      riskLevel = "HIGH RISK";
      riskColor = Colors.red;
      showHighRisk();
    }
    else if (riskScore > 40) {
      riskLevel = "MEDIUM RISK";
      riskColor = Colors.orange;
      showMediumRisk();
    }
    else {
      riskLevel = "LOW RISK";
      riskColor = Colors.green;
      goToPayment();
    }

    setState(() {});
  }

  /// 🧠 AI Explanation Logic
  String getRiskReason(String qrData, int riskScore) {

    List<String> reasons = [];

    if (qrData.contains("scam")) {
      reasons.add("Suspicious QR source detected");
    }

    if (riskScore > 75) {
      reasons.add("High-risk transaction pattern");
    }

    if (qrData.contains("unknown")) {
      reasons.add("Unverified receiver");
    }

    if (riskScore > 40 && riskScore <= 75) {
      reasons.add("Moderate risk behavior observed");
    }

    if (reasons.isEmpty) {
      reasons.add("No suspicious activity detected");
    }

    return reasons.join("\n• ");
  }

  void showHighRisk() {
    fraudHistory.add(
      FraudLog(
        reason: riskReason,
        riskScore: riskScore,
        time: TimeOfDay.now().format(context),
      ),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠ Scam Alert"),
        content: Text(
          "Risk Score: $riskScore%\n\n⚠ Reason:\n• $riskReason\n\nTransaction Blocked.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void showMediumRisk() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠ Warning"),
        content: Text(
          "Risk Score: $riskScore%\n\n⚠ Reason:\n• $riskReason\n\nProceed carefully.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              goToPayment();
            },
            child: const Text("Proceed"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void goToPayment() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          qrData: widget.qrData,
          riskScore: riskScore,
          receiverName: "Scanned Merchant", // ✅ IMPORTANT FIX
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const CircularProgressIndicator(color: Colors.green),

            const SizedBox(height: 20),

            const Text(
              "Analyzing Transaction...",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),

            const SizedBox(height: 15),

            Text(
              "Risk Score: $riskScore%",
              style: TextStyle(
                color: riskColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              riskLevel,
              style: TextStyle(
                color: riskColor,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 AI Explanation UI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "⚠ Reason:\n $riskReason",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentPage extends StatefulWidget {  
  final String qrData;
  final int riskScore;
  final String receiverName;

  const PaymentPage({
    super.key,
    required this.qrData,
    required this.riskScore,
    this.receiverName = "Divakar", // 👈 default name
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {

  TextEditingController amountController = TextEditingController();
  TextEditingController intentController = TextEditingController();

  final List<String> intents = [
    "Paying a friend",
    "Shopping",
    "Food order",
    "Bill payment",
    "Subscription",
    "Other"
  ];

  /// 🔍 Intent Detection
  bool isSuspiciousIntent(String intent) {
    final keywords = [
      "urgent",
      "lottery",
      "gift",
      "free",
      "reward",
      "verify",
      "refund",
      "claim"
    ];

    for (var word in keywords) {
      if (intent.toLowerCase().contains(word)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("UPI Payment"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 20),

            const Text("Paying To",
                style: TextStyle(fontSize: 16, color: Colors.grey)),

            Text(
              widget.receiverName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            /// AMOUNT
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter Amount (₹)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// INTENT
            TextField(
              controller: intentController,
              decoration: const InputDecoration(
                labelText: "Payment Purpose / Intent",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            /// QUICK INTENTS
            Wrap(
              spacing: 10,
              children: intents.map((intent) {
                return ChoiceChip(
                  label: Text(intent),
                  selected: intentController.text == intent,
                  onSelected: (_) {
                    setState(() {
                      intentController.text = intent;
                    });
                  },
                );
              }).toList(),
            ),

            const Spacer(),

            /// PAY BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(15),
                ),
                onPressed: () {

                  if (amountController.text.isEmpty) return;

                  bool suspicious =
                      isSuspiciousIntent(intentController.text);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpiPinPage(
                        amount: amountController.text,
                        riskScore: widget.riskScore,
                        suspiciousIntent: suspicious,
                      ),
                    ),
                  );
                },
                child: const Text("Pay Now"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class UpiPinPage extends StatefulWidget {
  final String amount;
  final int riskScore;
  final bool suspiciousIntent;
  final bool isBalanceCheck; // 👈 NEW

  const UpiPinPage({
    super.key,
    required this.amount,
    required this.riskScore,
    required this.suspiciousIntent,
    this.isBalanceCheck = false, // 👈 default
  });

  @override
  State<UpiPinPage> createState() => _UpiPinPageState();
}

class _UpiPinPageState extends State<UpiPinPage> {

  String pin = "";

  void addDigit(String digit) {
    if (pin.length < 4) {
      setState(() {
        pin += digit;
      });

      if (pin.length == 4) {

        Future.delayed(const Duration(milliseconds: 300), () {

          /// 🔐 BALANCE CHECK FLOW
          if (widget.isBalanceCheck) {

            Navigator.pop(context, true); // 👈 return success
            return;
          }

          /// 🔐 NORMAL FLOW
          if (widget.riskScore > 40 || widget.suspiciousIntent) {

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LivenessPage(amount: widget.amount),
              ),
            );

          } else {

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SuccessPage(
                      amount: widget.amount,
                      amountValue: double.parse(widget.amount)
                    ),
                ),
            );

          }

        });
      }
    }
  }

  void removeDigit() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              widget.isBalanceCheck
                  ? "Enter UPI PIN to View Balance"
                  : "Enter UPI PIN",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (!widget.isBalanceCheck)
              Text("Paying ₹${widget.amount}"),

            const SizedBox(height: 30),

            /// PIN DOTS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.all(8),
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: index < pin.length
                        ? Colors.green
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            /// KEYPAD
            Expanded(
              child: GridView.builder(
                itemCount: 12,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemBuilder: (context, index) {

                  if (index == 9) return const SizedBox();

                  if (index == 10) {
                    return keyButton("0");
                  }

                  if (index == 11) {
                    return IconButton(
                      icon: const Icon(Icons.backspace),
                      onPressed: removeDigit,
                    );
                  }

                  return keyButton("${index + 1}");
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget keyButton(String number) {
    return GestureDetector(
      onTap: () => addDigit(number),
      child: Center(
        child: Text(
          number,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class LivenessPage extends StatefulWidget {
  final String amount;

  const LivenessPage({super.key, required this.amount});

  @override
  State<LivenessPage> createState() => _LivenessPageState();
}

class _LivenessPageState extends State<LivenessPage> {

  bool verified = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Liveness Check"),
        backgroundColor: Colors.green,
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(Icons.face, size: 80, color: Colors.green),

            const SizedBox(height: 20),

            const Text(
              "Blink your eyes to verify",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {

                setState(() {
                  verified = true;
                });

                Future.delayed(const Duration(seconds: 1), () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SuccessPage(
                            amount: widget.amount,
                            amountValue: double.parse(widget.amount),
                        ),
                    ),
                  );
                });
              },
              child: const Text("Simulate Blink"),
            ),

            if (verified)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  "✔ Verified",
                  style: TextStyle(color: Colors.green),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class SuccessPage extends StatefulWidget {
  final String amount;
  final double amountValue;

  const SuccessPage({
    super.key,
    required this.amount,
    required this.amountValue,
  });

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {

  @override
  void initState() {
    super.initState();

    walletBalance -= widget.amountValue; // ✅ deduct once
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.green,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(Icons.check_circle, color: Colors.white, size: 80),

            const SizedBox(height: 20),

            const Text(
              "Payment Successful",
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),

            const SizedBox(height: 10),

            Text(
              "₹${widget.amount} sent",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class SendMoneyPage extends StatefulWidget {
  final String name;

  const SendMoneyPage({super.key, required this.name});

  @override
  State<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage> {

  TextEditingController amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Money"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const SizedBox(height: 30),

            /// Receiver Profile
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green.shade100,
              child: Text(
                widget.name[0],
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            /// Amount Field
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter Amount",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(15),
                ),
                onPressed: () {

                  String amount = amountController.text;

                  if(amount.isNotEmpty){

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "₹$amount sent to ${widget.name}",
                        ),
                      ),
                    );

                    Navigator.pop(context);
                  }
                },

                child: const Text(
                  "Send Money",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  bool showBalance = false;
  int selectedIndex = 0;

  final List<String> people = [
    "Rahul","Priya","Arun","Sneha","Karthik","Divya","Vikram","Ananya"
  ];

  final List<String> businesses = [
    "Amazon","Flipkart","Swiggy","Zomato","Uber","Ola","Netflix","Spotify"
  ];

  @override
Widget build(BuildContext context) {

  return Scaffold(

    floatingActionButton: FloatingActionButton(
      backgroundColor: Colors.green,
      child: const Icon(Icons.qr_code_scanner),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScanPage()),
        );
      },
    ),

    bottomNavigationBar: BottomNavigationBar(
      backgroundColor: Colors.green,
      currentIndex: selectedIndex,
      onTap: (index){
        setState(() {
          selectedIndex = index;
        });
      },
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Scam Check"),
      ],
    ),

    body: selectedIndex == 0
    ? homeContent()
    : selectedIndex == 1
        ? const HistoryPage()
        : const ScamDetectionPage(),
    );
  }

  Widget homeContent() {
  return SafeArea(
    child: Column(
      children: [

        /// 🔥 FIXED HEADER
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade700],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      "assets/logo.png",
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "SentryPay",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                ],
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                child: const CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage("assets/profile.jpg"),
                ),
              ),
            ],
          ),
        ),

        /// 🔽 SCROLLABLE CONTENT
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 💳 BALANCE CARD
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text("Wallet Balance",
                          style: TextStyle(color: Colors.grey)),

                      const SizedBox(height: 10),

                      showBalance
                          ? Text(
                              "₹ ${walletBalance.toStringAsFixed(2)}",
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                            )
                          : const Text(
                              "••••••••",
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                            ),

                      const SizedBox(height: 10),

                      GestureDetector(
                        onTap: () {
                          if (!showBalance) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UpiPinPage(
                                  amount: "0",
                                  riskScore: 0,
                                  suspiciousIntent: false,
                                  isBalanceCheck: true,
                                ),
                              ),
                            ).then((value) {
                              if (value == true) {
                                setState(() {
                                  showBalance = true;
                                });
                              }
                            });
                          } else {
                            setState(() {
                              showBalance = false;
                            });
                          }
                        },
                        child: Text(
                          showBalance
                              ? "Hide Balance"
                              : "View Balance",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// ⚡ QUICK ACTIONS
                const Text("Quick Actions",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Row(
                    children: [
                      const Spacer(flex: 1),
                      quickAction(Icons.send, "Send", () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const SendUserPage())
                        );
                      }),
                      const Spacer(flex: 2),
                      quickAction(Icons.receipt_long, "Bills", () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const BillsPage())
                        );
                      }),
                      const Spacer(flex: 2),
                      quickAction(Icons.request_page, "Request", () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const RequestPage())
                        );
                      }),
                      const Spacer(flex: 2),
                      quickAction(Icons.account_balance, "Transfer", () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const BankTransferPage())
                        );
                      }),
                      const Spacer(flex: 1)
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// 👥 PEOPLE
                const Text("People",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                const SizedBox(height: 30),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: people.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    return peopleAvatar(people[index]);
                  },
                ),

                const SizedBox(height: 10),

                /// 🏢 BUSINESSES
                const Text("Businesses",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                const SizedBox(height: 30),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: businesses.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    return peopleAvatar(businesses[index]);
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    ),
  );
} 

  Widget quickAction(IconData icon, String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    ),
  );
}

  Widget peopleAvatar(String name) {
    return GestureDetector(
      onTap: () {

      /// 👇 Navigate to Payment Page directly
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            qrData: "manual://pay", // 👈 dummy source
            riskScore: 10, // 👈 LOW risk (safe contact)
            receiverName: name,
          ),
        ),
      );

    },

    child: Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.green.shade100,
          child: Text(
            name[0],
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
          const SizedBox(height: 5),
          Text(
            name,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }
}
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        backgroundColor: Colors.green,
      ),

      body: fraudHistory.isEmpty
          ? const Center(
              child: Text("No Payments are done yet!"),
            )
          : ListView.builder(
              itemCount: fraudHistory.length,
              itemBuilder: (context, index) {

                final item = fraudHistory[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(

                    leading: const Icon(Icons.warning, color: Colors.red),

                    title: Text("Risk: ${item.riskScore}%"),

                    subtitle: Text(
                      "⚠ ${item.reason}\nTime: ${item.time}",
                    ),

                    trailing: const Text(
                      "Blocked",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class SendUserPage extends StatefulWidget {
  const SendUserPage({super.key});

  @override
  State<SendUserPage> createState() => _SendUserPageState();
}

class _SendUserPageState extends State<SendUserPage> {
  TextEditingController userController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Send Money"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: userController,
              decoration: const InputDecoration(
                labelText: "Enter Mobile Number / Username",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (userController.text.isEmpty) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentPage(
                      qrData: "manual://pay",
                      riskScore: 20,
                      receiverName: userController.text,
                    ),
                  ),
                );
              },
              child: const Text("Proceed"),
            )
          ],
        ),
      ),
    );
  }
}

class BillsPage extends StatelessWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bills"), backgroundColor: Colors.green),
      body: const Center(
        child: Text(
          "No bills right now",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  TextEditingController userController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Money"), backgroundColor: Colors.green),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: userController,
              decoration: const InputDecoration(
                labelText: "Enter Mobile Number / Username",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (userController.text.isEmpty) return;

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Request Sent"),
                    content: Text("Request sent to ${userController.text}"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text("OK"),
                      )
                    ],
                  ),
                );
              },
              child: const Text("Send Request"),
            )
          ],
        ),
      ),
    );
  }
}

class BankTransferPage extends StatefulWidget {
  const BankTransferPage({super.key});

  @override
  State<BankTransferPage> createState() => _BankTransferPageState();
}

class _BankTransferPageState extends State<BankTransferPage> {

  TextEditingController accController = TextEditingController();
  TextEditingController ifscController = TextEditingController();
  TextEditingController bankController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Bank Transfer"), backgroundColor: Colors.green),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller: accController,
              decoration: const InputDecoration(
                labelText: "Account Number",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: ifscController,
              decoration: const InputDecoration(
                labelText: "IFSC Code",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: bankController,
              decoration: const InputDecoration(
                labelText: "Bank Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {

                if (accController.text.isEmpty ||
                    ifscController.text.isEmpty ||
                    bankController.text.isEmpty) {
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentPage(
                      qrData: "bank://transfer",
                      riskScore: 30,
                      receiverName: bankController.text,
                    ),
                  ),
                );
              },
              child: const Text("Proceed"),
            )
          ],
        ),
      ),
    );
  }
}

class ScamDetectionPage extends StatefulWidget {
  const ScamDetectionPage({super.key});

  @override
  State<ScamDetectionPage> createState() => _ScamDetectionPageState();
}

class _ScamDetectionPageState extends State<ScamDetectionPage> {

  TextEditingController messageController = TextEditingController();

  String result = "";
  Color resultColor = Colors.green;
  String reason = "";

  void analyzeMessage() {

    String text = messageController.text.toLowerCase();

    List<String> scamKeywords = [
      "urgent",
      "lottery",
      "win",
      "prize",
      "free",
      "click link",
      "verify",
      "otp",
      "refund",
      "claim",
      "limited offer",
    ];

    bool isScam = false;
    List<String> detected = [];

    for (var word in scamKeywords) {
      if (text.contains(word)) {
        isScam = true;
        detected.add(word);
      }
    }

    setState(() {
      if (isScam) {
        result = "⚠ Scam Detected";
        resultColor = Colors.red;
        reason = "Suspicious keywords: ${detected.join(", ")}";
      } else {
        result = "✅ Safe Message";
        resultColor = Colors.green;
        reason = "No suspicious patterns detected";
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scam Detection"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Paste or Enter Message",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Enter suspicious message here...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: analyzeMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(15),
                ),
                child: const Text("Analyze"),
              ),
            ),

            const SizedBox(height: 30),

            if (result.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      result,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(reason),

                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            const SizedBox(height: 20),

            /// PROFILE AVATAR
            CircleAvatar(
              radius: 50,
              backgroundImage: const AssetImage("assets/profile.jpg"),
            ),

            const SizedBox(height: 20),

            /// NAME
            const Text(
              "Hematharaa Srinivasan",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            /// DETAILS CARD
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                  )
                ],
              ),

              child: Column(
                children: [

                  profileItem(Icons.account_balance_wallet, "UPI ID", "hemtharaicici@sentrypay"),
                  const Divider(),

                  profileItem(Icons.phone, "Mobile", "90034 09441"),
                  const Divider(),

                  profileItem(Icons.account_balance, "Bank", "Indian Overseas Bank"),

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget profileItem(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}