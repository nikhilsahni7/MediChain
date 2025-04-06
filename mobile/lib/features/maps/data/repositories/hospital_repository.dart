import 'package:medileger/core/services/api_service.dart';
import 'package:medileger/features/maps/data/models/hospital_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HospitalRepository {
  final ApiService _apiService;

  HospitalRepository(this._apiService);

  Future<List<Hospital>> getAllHospitals() async {
    final response = await _apiService.get('/hospitals');
    final List<dynamic> hospitalsJson = response['data'];
    return hospitalsJson.map((json) => Hospital.fromJson(json)).toList();
  }

  Future<Hospital> getHospitalById(String id) async {
    final response = await _apiService.get('/hospitals/$id');
    return Hospital.fromJson(response['data']);
  }

  Future<List<Hospital>> getNearbyHospitals(
      double latitude, double longitude, double distance) async {
    final response = await _apiService
        .get('/hospitals/nearby/$latitude/$longitude/$distance');
    final List<dynamic> hospitalsJson = response['data'];
    return hospitalsJson.map((json) => Hospital.fromJson(json)).toList();
  }
}

// Provider for HospitalRepository
final hospitalRepositoryProvider = Provider<HospitalRepository>((ref) {
  return HospitalRepository(ApiService());
});

// Provider for all hospitals
final allHospitalsProvider = FutureProvider<List<Hospital>>((ref) {
  final repository = ref.watch(hospitalRepositoryProvider);
  return repository.getAllHospitals();
});

// Provider for nearby hospitals
final nearbyHospitalsProvider =
    FutureProvider.family<List<Hospital>, Map<String, dynamic>>(
  (ref, params) {
    final repository = ref.watch(hospitalRepositoryProvider);
    return repository.getNearbyHospitals(
      params['latitude'] as double,
      params['longitude'] as double,
      params['distance'] as double,
    );
  },
);
