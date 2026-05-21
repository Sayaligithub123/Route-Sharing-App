import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class JoinRequestModal extends StatefulWidget {
  final String requestId;
  final String name;
  final String seats;
  final String phone;
  final Function(bool accepted)? onResponded;

  const JoinRequestModal({
    super.key,
    required this.requestId,
    required this.name,
    required this.seats,
    required this.phone,
    this.onResponded,
  });

  @override
  State<JoinRequestModal> createState() => _JoinRequestModalState();
}

class _JoinRequestModalState extends State<JoinRequestModal> {
  bool isLoading = false;

  Future<void> _respond(String status) async {
    setState(() { isLoading = true; });

    final url = Uri.parse("http://192.168.186.81:5000/api/rides/respond");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "requestId": widget.requestId,
          "status": status,
        }),
      );

      if (response.statusCode == 200) {
        widget.onResponded?.call(status == "accepted");
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Request ${status}!")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response.body}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network error: $e")),
        );
      }
    }
    if (mounted) setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// HANDLE BAR
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "New join request! Review below",
              style: TextStyle(color: Colors.orange),
            ),
          ),
          Text(
            "Respond within 60 seconds",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),

          SizedBox(height: 16),

          /// 👤 PASSENGER INFO CARD
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFFEF3C7),
                      child: Text(
                        widget.name.isNotEmpty ? widget.name[0] : "?",
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text("📞", style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              widget.phone,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        Text(
                          "Seats requested: ${widget.seats}",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),

                Divider(height: 20),

                _fareRow("Extra you earn", "+₹48", isGreen: true, bigFont: true),
                _fareRow("Detour added", "~3 min"),
              ],
            ),
          ),

          SizedBox(height: 16),

          /// 🚀 BUTTONS
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond("rejected"),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("Decline"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respond("accepted"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1A9E6E),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("Accept +₹48"),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _fareRow(String label, String value, {bool isGreen = false, bool bigFont = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontSize: bigFont ? 16 : 13,
              fontWeight: FontWeight.w600,
              color: isGreen ? Color(0xFF1A9E6E) : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
