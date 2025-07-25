import 'package:flutter/material.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/trainer_detail.dart';
import '../models/trainer_client.dart';
import '../models/trainer_review.dart';

class TrainerService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch all trainers
  Future<List<UserProfile>> getAllTrainers() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('role', 'trainer')
          .order('created_at', ascending: false);

      return response.map((data) => UserProfile.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error fetching trainers: $e');
      return [];
    }
  }

  // Fetch trainer details by trainer ID
  Future<TrainerDetail?> getTrainerDetails(String trainerId) async {
    try {
      final response = await _client
          .from('trainer_details')
          .select()
          .eq('id', trainerId)
          .maybeSingle();

      if (response == null) return null;
      return TrainerDetail.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching trainer details: $e');
      return null;
    }
  }

  // Update or create trainer details
  Future<bool> updateTrainerDetails(TrainerDetail trainerDetail) async {
    try {
      // Check if trainer details exist
      final exists = await _client
          .from('trainer_details')
          .select('id')
          .eq('id', trainerDetail.id)
          .maybeSingle();

      if (exists == null) {
        // Create new trainer details
        await _client.from('trainer_details').insert(trainerDetail.toJson());
      } else {
        // Update existing trainer details
        await _client
            .from('trainer_details')
            .update(trainerDetail.toJson())
            .eq('id', trainerDetail.id);
      }
      return true;
    } catch (e) {
      debugPrint('Error updating trainer details: $e');
      return false;
    }
  }

  // Get trainer reviews
  Future<List<TrainerReview>> getTrainerReviews(String trainerId) async {
    try {
      final response = await _client
          .from('trainer_reviews')
          .select()
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);

      return response.map((data) => TrainerReview.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error fetching trainer reviews: $e');
      return [];
    }
  }

  // Add or update a review
  Future<bool> saveTrainerReview(TrainerReview review) async {
    try {
      // Check if review exists
      final exists = await _client
          .from('trainer_reviews')
          .select('id')
          .eq('trainer_id', review.trainerId)
          .eq('client_id', review.clientId)
          .maybeSingle();

      if (exists == null) {
        // Create new review
        await _client.from('trainer_reviews').insert(review.toJson());
      } else {
        // Update existing review
        await _client
            .from('trainer_reviews')
            .update({
              'rating': review.rating,
              'review': review.review,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('trainer_id', review.trainerId)
            .eq('client_id', review.clientId);
      }
      return true;
    } catch (e) {
      debugPrint('Error saving trainer review: $e');
      return false;
    }
  }

  // Delete a review
  Future<bool> deleteTrainerReview(String reviewId) async {
    try {
      await _client.from('trainer_reviews').delete().eq('id', reviewId);
      return true;
    } catch (e) {
      debugPrint('Error deleting trainer review: $e');
      return false;
    }
  }

  // Get trainer-client relationships for a trainer
  Future<List<TrainerClient>> getTrainerClients(String trainerId) async {
    try {
      final response = await _client
          .from('trainer_clients')
          .select()
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);

      return response.map((data) => TrainerClient.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error fetching trainer clients: $e');
      return [];
    }
  }

  // Get trainer-client relationships for a client
  Future<List<TrainerClient>> getClientTrainers(String clientId) async {
    try {
      final response = await _client
          .from('trainer_clients')
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      return response.map((data) => TrainerClient.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error fetching client trainers: $e');
      return [];
    }
  }

  // Create or update trainer-client relationship
  Future<bool> updateTrainerClientRelationship(
      TrainerClient relationship) async {
    try {
      // Check if relationship exists
      final exists = await _client
          .from('trainer_clients')
          .select('id')
          .eq('trainer_id', relationship.trainerId)
          .eq('client_id', relationship.clientId)
          .maybeSingle();

      if (exists == null) {
        // Create new relationship
        await _client.from('trainer_clients').insert(relationship.toJson());
      } else {
        // Update existing relationship
        await _client
            .from('trainer_clients')
            .update({
              'status': relationship.status,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('trainer_id', relationship.trainerId)
            .eq('client_id', relationship.clientId);
      }
      return true;
    } catch (e) {
      debugPrint('Error updating trainer-client relationship: $e');
      return false;
    }
  }

  // Request a trainer (client -> trainer)
  Future<bool> requestTrainer(String clientId, String trainerId) async {
    try {
      final relationship = TrainerClient(
        id: '', // Will be generated by the database
        trainerId: trainerId,
        clientId: clientId,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return await updateTrainerClientRelationship(relationship);
    } catch (e) {
      debugPrint('Error requesting trainer: $e');
      return false;
    }
  }

  // Accept or reject client request (trainer -> client)
  Future<bool> respondToClientRequest(
      String trainerId, String clientId, bool accept) async {
    try {
      final status = accept ? 'active' : 'rejected';
      final relationship = TrainerClient(
        id: '', // Will be updated by updateTrainerClientRelationship
        trainerId: trainerId,
        clientId: clientId,
        status: status,
        createdAt: DateTime.now(), // Will be updated if exists
        updatedAt: DateTime.now(),
      );
      return await updateTrainerClientRelationship(relationship);
    } catch (e) {
      debugPrint('Error responding to client request: $e');
      return false;
    }
  }

  // End trainer-client relationship (can be initiated by either party)
  Future<bool> endTrainerClientRelationship(
      String trainerId, String clientId) async {
    try {
      final relationship = TrainerClient(
        id: '', // Will be updated by updateTrainerClientRelationship
        trainerId: trainerId,
        clientId: clientId,
        status: 'ended',
        createdAt: DateTime.now(), // Will be updated if exists
        updatedAt: DateTime.now(),
      );
      return await updateTrainerClientRelationship(relationship);
    } catch (e) {
      debugPrint('Error ending trainer-client relationship: $e');
      return false;
    }
  }

  // Check if user is a client of a trainer
  Future<bool> isClientOfTrainer(String clientId, String trainerId) async {
    try {
      final response = await _client
          .from('trainer_clients')
          .select()
          .eq('trainer_id', trainerId)
          .eq('client_id', clientId)
          .eq('status', 'active')
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking trainer-client relationship: $e');
      return false;
    }
  }

  // Get client profile details for a trainer
  Future<List<UserProfile>> getTrainerClientProfiles(String trainerId) async {
    try {
      // First get all active client relationships
      final relationships = await _client
          .from('trainer_clients')
          .select('client_id')
          .eq('trainer_id', trainerId)
          .eq('status', 'active');

      if (relationships.isEmpty) return [];

      // Extract client IDs
      final clientIds =
          relationships.map((r) => r['client_id'] as String).toList();

      // Then fetch the actual profile data for these clients
      final clientProfiles =
          await _client.from('profiles').select().inFilter('id', clientIds);

      return clientProfiles.map((data) => UserProfile.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error fetching trainer client profiles: $e');
      return [];
    }
  }

  // Assign a workout program to a client
  Future<bool> assignWorkoutProgramToClient(
      WorkoutProgram program, String clientId, String trainerId) async {
    try {
      // First check if this trainer is actually training this client
      final isClient = await isClientOfTrainer(clientId, trainerId);
      if (!isClient) {
        debugPrint('Cannot assign program: not a client of this trainer');
        return false;
      }

      // Set the program's owner to the client
      final clientProgram = program.copyWith(
        userId: clientId,
        trainerId: trainerId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Insert the program
      await _client.from('workout_programs').insert(clientProgram.toJson());
      return true;
    } catch (e) {
      debugPrint('Error assigning workout program to client: $e');
      return false;
    }
  }
}
