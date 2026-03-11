import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/fcm_bloc.dart';
import '../bloc/fcm_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('DAMO'),
      ),
      body: BlocConsumer<FcmBloc, FcmState>(
        listener: (context, state) {
          if (state.lastMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${state.lastMessage!.title}: ${state.lastMessage!.body}',
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        listenWhen: (prev, curr) => prev.lastMessage != curr.lastMessage,
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FCM Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  state.token.isEmpty
                      ? 'FCM 토큰 대기중...'
                      : 'FCM 토큰: ${state.token.substring(0, 20)}...',
                ),
                const SizedBox(height: 16),
                if (state.lastMessage != null) ...[
                  const Text(
                    '마지막 알림',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.lastMessage!.title}: ${state.lastMessage!.body}',
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
