import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        backgroundColor: Colors.green,
      ),

      body: MobileScanner(

        onDetect: (BarcodeCapture capture) {

          for (final barcode in capture.barcodes) {

            final String? code = barcode.rawValue;

            if (code != null) {

              /// LEGIT PAYMENT QR
              if (code.contains("sentrypay://pay")) {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentPage(qrData: code),
                  ),
                );

              }

              /// FRAUD QR
              else if (code.contains("sentrypay://scam")) {

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(

                    title: const Text("⚠ Scam Alert"),

                    content: const Text(
                      "This QR code is flagged as suspicious.\nDo not proceed with payment."
                    ),

                    actions: [

                      TextButton(
                        onPressed: (){
                          Navigator.pop(context);
                        },
                        child: const Text("OK"),
                      )

                    ],

                  ),
                );

              }

              /// UNKNOWN QR
              else {

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Unknown QR Code"),
                  ),
                );

              }

            }

          }

        },

      ),
    );
  }
}

class PaymentPage extends StatelessWidget {

  final String qrData;

  const PaymentPage({super.key, required this.qrData});

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
          children: [

            const SizedBox(height: 30),

            const Text(
              "Pay To",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 10),

            const Text(
              "Rahul",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter Amount",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(15),
              ),
              onPressed: (){

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Payment Successful"),
                  ),
                );

              },

              child: const Text("Pay"),
            )

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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
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
                        ),
                      )
                    ],
                  ),

                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, color: Colors.white),
                  )
                ],
              ),

              const SizedBox(height: 25),

              /// BALANCE CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Wallet Balance",
                      style: TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 10),

                    showBalance
                        ? const Text(
                            "₹ 12,450.84",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Text(
                            "••••••••",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: (){
                        setState(() {
                          showBalance = !showBalance;
                        });
                      },
                      child: Text(
                        showBalance ? "Hide Balance" : "View Balance",
                        style: const TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// QUICK ACTIONS
              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  quickAction(Icons.send, "Send"),
                  quickAction(Icons.receipt_long, "Bills"),
                  quickAction(Icons.request_page, "Requests"),
                  quickAction(Icons.savings, "Savings"),
                ],
              ),

              const SizedBox(height: 30),

              /// PEOPLE SECTION
              const Text(
                "People",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 25),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: people.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                ),
                itemBuilder: (context,index){
                  return peopleAvatar(people[index]);
                },
              ),

              const SizedBox(height: 30),

              /// BUSINESS SECTION
              const Text(
                "Businesses",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 25),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: businesses.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 15,
                ),
                itemBuilder: (context,index){
                  return peopleAvatar(businesses[index]);
                },
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget quickAction(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.green.shade100,
          child: Icon(icon, color: Colors.green),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget peopleAvatar(String name) {

    return GestureDetector(

      onTap: () {

        Navigator.push(
          context,
            MaterialPageRoute(
            builder: (context) => SendMoneyPage(name: name),
          ),
        );

      },

      child: Column(
        children: [

          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.green.shade100,
            child: Text(
              name[0],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.green,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            name,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          )

        ],
      ),
    );
  }  
}