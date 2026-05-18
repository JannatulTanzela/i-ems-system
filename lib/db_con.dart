import 'package:supabase_flutter/supabase_flutter.dart';

class DBCon {
  static final supabase = Supabase.instance.client;

  static Future init() async {
    await Supabase.initialize(
      url: 'https://ydhcpikpudjxsnyfxbvh.supabase.co',
      anonKey: 'sb_publishable_2g1-ggTpq83NP4ndB0IsOA_hC72v9oA',
    );
  }
}