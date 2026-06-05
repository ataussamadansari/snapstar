import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriberProvider {
  SubscriberProvider(this._client);

  final SupabaseClient _client;

  Future<void> subscribe(Map<String, dynamic> data) async {
    await _client.from('subscribes').insert(data);
  }

  Future<void> unsubscribe({
    required String subscriberId,
    required String subscribedId,
  }) async {
    await _client
        .from('subscribes')
        .delete()
        .eq('subscriber_id', subscriberId)
        .eq('subscribed_id', subscribedId);
  }

  Future<Map<String, dynamic>?> getSubscription({
    required String subscriberId,
    required String subscribedId,
  }) async {
    final response = await _client
        .from('subscribes')
        .select()
        .eq('subscriber_id', subscriberId)
        .eq('subscribed_id', subscribedId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> getSubscribers(String userId) async {
    final res = await _client
        .from('subscribes')
        .select('*, users!subscribes_subscriber_id_fkey(*)')
        .eq('subscribed_id', userId);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getSubscribing(String userId) async {
    final res = await _client
        .from('subscribes')
        .select('*, users!subscribes_subscribed_id_fkey(*)')
        .eq('subscriber_id', userId);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getUsersExcluding({
    required String userId,
    required int limit,
    required int offset,
  }) async {
    final res = await _client
        .from('users')
        .select()
        .neq('id', userId)
        .eq('is_anonymous', false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<int> fetchSubscriberCount(String userId) async {
    final response = await _client
        .from('users')
        .select('subscriber_count')
        .eq('id', userId)
        .maybeSingle();
    return (response?['subscriber_count'] as num?)?.toInt() ?? 0;
  }

  Future<int> fetchSubscribingCount(String userId) async {
    final response = await _client
        .from('users')
        .select('subscribing_count')
        .eq('id', userId)
        .maybeSingle();
    return (response?['subscribing_count'] as num?)?.toInt() ?? 0;
  }
}
