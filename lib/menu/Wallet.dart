import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parking1/drawer.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  double balance = 0.0;
  List<Map<String, String>> transactions = [];
  final TextEditingController _fundsController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadDataFromFirebase();
  }

  // Load data from Firestore
  Future<void> _loadDataFromFirebase() async {
    try {
      final docSnapshot = await _firestore.collection('wallet').doc('user_wallet').get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          balance = (data['balance'] ?? 0.0).toDouble();

          // Safely parse transactions and cast to List<Map<String, String>>
          transactions = (data['transactions'] as List<dynamic>? ?? []).map((dynamic transaction) {
            if (transaction is Map<String, dynamic>) {
              return transaction.map((key, value) {
                return MapEntry(key.toString(), value.toString());
              });
            }
            return <String, String>{};
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load wallet data: $e')),
      );
    }
  }

  // Add funds to the wallet
  void addFunds(double amount) {
    setState(() {
      balance += amount;
      String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      transactions.add({
        'type': 'Added',
        'amount': '\$${amount.toStringAsFixed(2)}',
        'timestamp': timestamp,
      });
    });
    _saveDataToFirebase(); // Save updated data to Firebase
  }

  // Purchase ticket and update wallet
  bool purchaseTicket(double price) {
    if (balance >= price) {
      setState(() {
        balance -= price;
        String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        transactions.add({
          'type': 'Purchased',
          'amount': '\$${price.toStringAsFixed(2)}',
          'timestamp': timestamp,
        });
      });
      _saveDataToFirebase(); // Save updated data to Firebase
      return true;
    } else {
      return false;
    }
  }

  // Save wallet data to Firestore
  Future<void> _saveDataToFirebase() async {
    try {
      await _firestore.collection('wallet').doc('user_wallet').set({
        'balance': balance,
        'transactions': transactions.map((transaction) {
          return {
            'type': transaction['type'],
            'amount': transaction['amount'],
            'timestamp': transaction['timestamp'],
          };
        }).toList(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save wallet data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: FutureBuilder(
        future: _loadDataFromFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Wallet Balance
                Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Balance:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),

                // Add Funds Section
                TextField(
                  controller: _fundsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter Amount to Add',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add, color: Colors.blue),
                      onPressed: () {
                        double amount = double.tryParse(_fundsController.text) ?? 0;
                        if (amount > 0) {
                          addFunds(amount);
                          _fundsController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid amount')),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Purchase Ticket Button
                ElevatedButton(
                  onPressed: () {
                    bool success = purchaseTicket(30.0);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ticket Purchased')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Insufficient funds')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Buy Ticket for \$30',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),

                // Transaction History
                const Text(
                  'Transaction History:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                              '${transactions[index]['type']} ${transactions[index]['amount']}'),
                          subtitle: Text('Date: ${transactions[index]['timestamp']}'),
                          trailing: const Icon(
                            Icons.history,
                            color: Colors.blue,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      drawer: drawer_menu(),
    );
  }
}
