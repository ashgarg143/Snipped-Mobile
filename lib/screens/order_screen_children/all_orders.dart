import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:snipped/screens/orders_screen.dart';
import 'dart:convert';

import 'package:snipped/models/Order.dart';

class AllOrders extends StatefulWidget {
  @override
  _AllOrdersState createState() => _AllOrdersState();
}

String _phone;
DateTime _date;
String strDate;
String _email;

class _AllOrdersState extends State<AllOrders> {
  @override
  void initState() {
    getPhonePreferences().then((value) {
      _phone = value;
    });
    getEmailPreferences()
        .then((value){
      _email = value;
    });
    _date = DateTime.now();
    strDate = _date.day.toString() + "-" + _date.month.toString() + "-" + _date.year.toString();
    super.initState();
  }

  Future<String> getPhonePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("userPhone") ?? "";
  }

  Future<String> getEmailPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("userEmail") ?? "";
  }

  Future<List<Order>> _getAllOrders() async {
    print("url called 2 is ${(_phone)}");
    String url =
        "http://3.0.235.136:8080/Snipped-0.0.1-SNAPSHOT/order/" + _phone;
    var data = await http.get(url);
    Response response = Response.fromJson(json.decode(data.body));
    return response.orders;
  }

  _cancelOrderDialog(value){
    bool refreshing = false;
    AlertDialog _deleteDialog = new AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      contentPadding: EdgeInsets.only(top: 10.0, bottom: 10.0),
      title: Text("Are you sure you want to cancel this order?"),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("Cancel"),
        ),
        FlatButton(
          onPressed: () {
            setState(() {
              refreshing = true;
            });
            _cancelOrder(value)
                .then((bool){
              _sendMail(value)
                  .then((bool){
                Navigator.pop(context);
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => OrdersScreen()));
              });
            });
          },
          child: Text("Yeah"),
        )
      ],
    );

    showDialog(
        context: context,
        builder: (BuildContext context) =>
        (refreshing)?
        Container(
          child: Dialog(
            child: CircularProgressIndicator(
              valueColor: new AlwaysStoppedAnimation<Color>(Color(0xffff7100)),
            ),
          )
        )
            :
            _deleteDialog
    );
  }

  Future<bool> _cancelOrder(value) async{
    String url = "http://3.0.235.136:8080/Snipped-0.0.1-SNAPSHOT/order/cancel/" + value;
    var data = await http.get(url);
    return true;
  }

  Future<bool> _sendMail(value) async{
    String url = "http://3.0.235.136:8080/Snipped-0.0.1-SNAPSHOT/mail/order_cancelled";
    Map<String, String> map = {
      "email" : _email,
      "orderId" : value
    };
    var data = await http.post(url, body: map);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: FutureBuilder(
          future: _getAllOrders(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              if(snapshot.data.length == 0){
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top : 48.0, bottom: 12.0),
                          child: Container(
                            child: Image.asset("images/noorder.png"),
                          ),
                        ),
                        Text(
                          "You haven't placed any orders!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.w600
                          ),
                        ),
                        Text(
                          "Place an order and come back here to check the status of your order! ^_^",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w300
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.90,
                    height: (strDate == snapshot.data[index].appointmentDate
                            ||snapshot.data[index].status == "Cancelled")?
                    snapshot.data[index].services.length * 35.0 + 210.0 :
                    snapshot.data[index].services.length * 35.0 + 257.0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 4.0, right: 4.0),
                      child: Card(
                        elevation: 5.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Padding(padding: EdgeInsets.only(top: 8.0)),
                            Container(
                              color: Color(0XFF073848),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      "Order id: ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white
                                      ),
                                    ),
                                    Text(
                                      snapshot.data[index].id.toString().substring(12),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xffff7100)
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              color: Colors.grey[200],
                              height: snapshot.data[index].services.length * 35.0,
                              child: ListView.builder(
                                itemCount: snapshot.data[index].services.length,
                                itemBuilder: (BuildContext context, int serviceIndex){
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(
                                          snapshot.data[index].services[serviceIndex].name,
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        Text(
                                          snapshot.data[index].services[serviceIndex].subcategory,
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        Text(
                                          "Rs. "+ snapshot.data[index].services[serviceIndex].price.toString(),
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(padding: EdgeInsets.only(top: 12.0)),
                            Padding(
                              padding: const EdgeInsets.only(left : 8.0, right: 8.0),
                              child: Container(
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        Text(
                                          "Appointment : ",
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        Text(
                                          snapshot.data[index].appointmentDate + ", " + snapshot.data[index].appointmentTime,
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(padding: EdgeInsets.only(top: 8.0)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        Text(
                                          "Coupon code : ",
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                        Text(
                                          snapshot.data[index].coupon,
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(padding: EdgeInsets.only(top: 8.0)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        Text(
                                          "Total amount : ",
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        Text(
                                          "Rs. " + snapshot.data[index].amount,
                                          style: TextStyle(
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Padding(padding: EdgeInsets.only(top: 22.0)),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.90,
                              height: 50.0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Column(
                                    children: <Widget>[
                                      Icon(
                                        Icons.check_circle,
                                        color: Color(0xffff7100),
                                      ),
                                      Text("Confirmed")
                                    ],
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.10,
                                    height: 2.0,
                                    color: Colors.grey[200],
                                    margin: EdgeInsets.only(left: 8.0, right: 8.0),
                                  ),
                                  (strDate == snapshot.data[index].appointmentDate
                                   || (snapshot.data[index].status == "Cancelled"))?
                                  Column(
                                    children: <Widget>[
                                      Icon(
                                        Icons.check_circle,
                                        color: Color(0xffff7100),
                                      ),
                                      Text("Processed")
                                    ],
                                  )
                                  : Column(
                                    children: <Widget>[
                                      Icon(
                                        Icons.watch_later,
                                        color: Color(0xff073848),
                                      ),
                                      Text("Processing")
                                    ],
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.10,
                                    height: 2.0,
                                    color: Colors.grey[200],
                                    margin: EdgeInsets.only(left: 8.0, right: 8.0),
                                  ),
                                  (snapshot.data[index].status == "Completed")?
                                  Column(
                                    children: <Widget>[
                                      Icon(
                                        Icons.check_circle,
                                        color: Color(0xffff7100),
                                      ),
                                      Text("Completed")
                                    ],
                                  )
                                      : new Container() ,
                                  (snapshot.data[index].status == "Pending")?
                                  Column(
                                    children: <Widget>[
                                      Icon(
                                        Icons.watch_later,
                                        color:  Color(0xff073848)
                                      ),
                                      Text("Completed")
                                    ],
                                  )
                                      : new Container() ,
                                  (snapshot.data[index].status == "Cancelled")?
                                  Column(
                                    children: <Widget>[
                                      Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                                      Text("Cancelled")
                                    ],
                                  )
                                      : new Container() ,
                                ],
                              )
                            ),
                            (strDate == snapshot.data[index].appointmentDate
                            || snapshot.data[index].status == "Cancelled")?
                            new Container()
                            : Container(
                              width: MediaQuery.of(context).size.width,
                              child: RaisedButton(
                                onPressed: (){
                                  _cancelOrderDialog(snapshot.data[index].id);
                                },
                                color: Color(0xff073848),
                                textColor: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                                  child: Text(
                                    "CANCEL ORDER",
                                    style: TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              return CircularProgressIndicator(
                valueColor: new AlwaysStoppedAnimation<Color>(Color(0xffff7100)),
              );
            }
          },
        ),
      ),
    );
  }
}
