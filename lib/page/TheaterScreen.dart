import 'package:flutter/material.dart';

class TheaterScreen extends StatefulWidget {
  @override
  _TheaterScreenState createState() => _TheaterScreenState();
}

class _TheaterScreenState extends State<TheaterScreen> {
  List<List<bool>> seats =
      List.generate(5, (row) => List.generate(8, (col) => false));

  void toggleSeat(int row, int col) {
    setState(() {
      seats[row][col] = !seats[row][col];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Select Your Seats"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text("Screen",
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const Divider(
              color: Colors.white, thickness: 2, indent: 50, endIndent: 50),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: GridView.builder(
                itemCount: seats.length * seats[0].length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  int row = index ~/ 8;
                  int col = index % 8;
                  return GestureDetector(
                    onTap: () => toggleSeat(row, col),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: seats[row][col] ? Colors.green : Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            onPressed: () {
              int selectedSeats =
                  seats.expand((row) => row).where((seat) => seat).length;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("You have booked $selectedSeats seats!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Book Now",
                style: TextStyle(color: Colors.black, fontSize: 16)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
