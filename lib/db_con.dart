import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  static var db, userCollection;
  
  // Update your MongoDB connection string here
  static const String mongoUrl = "mongodb://localhost:27017/i_ems";

  static connect() async {
    db = await Db.create(mongoUrl);
    await db.open();
    print("Connected to MongoDB");
    userCollection = db.collection("users");
  }
}
