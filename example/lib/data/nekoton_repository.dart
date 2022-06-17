import 'dart:async';

import 'package:async/async.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart' as http;
import 'package:nekoton_flutter/nekoton_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NekotonRepository {
  final _sharedPreferencesMemoizer = AsyncMemoizer<SharedPreferences>();
  final _storageMemoizer = AsyncMemoizer<Storage>();
  final _gqlConnectionMemoizer = AsyncMemoizer<GqlConnection>();
  final _jrpcConnectionMemoizer = AsyncMemoizer<JrpcConnection>();
  final _ledgerConnectionMemoizer = AsyncMemoizer<LedgerConnection>();
  final _keystoreMemoizer = AsyncMemoizer<Keystore>();
  final _accountsStorageMemoizer = AsyncMemoizer<AccountsStorage>();
  final _gqlTransportMemoizer = AsyncMemoizer<GqlTransport>();
  final _jrpcTransportMemoizer = AsyncMemoizer<JrpcTransport>();

  NekotonRepository();

  Future<void> intialize() async {
    await sharedPreferences;
    await storage;
    await gqlConnection;
    await jrpcConnection;
    await ledgerConnection;
    await keystore;
    await accountsStorage;
    await gqlTransport;
    await jrpcTransport;
  }

  Future<void> dispose() async {
    await storage.then((v) => v.freePtr());
    await gqlConnection.then((v) => v.freePtr());
    await jrpcConnection.then((v) => v.freePtr());
    await ledgerConnection.then((v) => v.freePtr());
    await keystore.then((v) => v.freePtr());
    await accountsStorage.then((v) => v.freePtr());
    await gqlTransport.then((v) => v.freePtr());
    await jrpcTransport.then((v) => v.freePtr());
  }

  Future<SharedPreferences> get sharedPreferences =>
      _sharedPreferencesMemoizer.runOnce(() => SharedPreferences.getInstance());

  Future<Storage> get storage => _storageMemoizer.runOnce(() async {
        final sharedPreferences = await this.sharedPreferences;

        return Storage(
          get: (key) async => sharedPreferences.getString(key),
          set: ({
            required String key,
            required String value,
          }) async =>
              sharedPreferences.setString(key, value),
          setUnchecked: ({
            required String key,
            required String value,
          }) =>
              sharedPreferences.setString(key, value),
          remove: (key) async => sharedPreferences.remove(key),
          removeUnchecked: (key) => sharedPreferences.remove(key),
        );
      });

  Future<GqlConnection> get gqlConnection => _gqlConnectionMemoizer.runOnce(
        () => GqlConnection(
          group: 'mainnet',
          settings: const GqlNetworkSettings(
            endpoints: [
              'https://eri01.main.everos.dev/graphql',
              'https://gra01.main.everos.dev/graphql',
              'https://gra02.main.everos.dev/graphql',
              'https://lim01.main.everos.dev/graphql',
              'https://rbx01.main.everos.dev/graphql',
            ],
            latencyDetectionInterval: 60000,
            maxLatency: 60000,
            endpointSelectionRetryCount: 5,
            local: false,
          ),
          post: ({
            required String endpoint,
            required Map<String, String> headers,
            required String data,
          }) =>
              http
                  .post(
                    Uri.parse(endpoint),
                    headers: headers,
                    body: data,
                  )
                  .then((value) => value.body),
          get: (String endpoint) => http
              .get(
                Uri.parse(endpoint),
              )
              .then((value) => value.body),
        ),
      );

  Future<JrpcConnection> get jrpcConnection => _jrpcConnectionMemoizer.runOnce(
        () => JrpcConnection(
          group: 'mainnet',
          settings: const JrpcNetworkSettings(endpoint: 'https://jrpc.everwallet.net/rpc'),
          post: ({
            required String endpoint,
            required Map<String, String> headers,
            required String data,
          }) =>
              http
                  .post(
                    Uri.parse(endpoint),
                    headers: headers,
                    body: data,
                  )
                  .then((value) => value.body),
        ),
      );

  Future<LedgerConnection> get ledgerConnection => _ledgerConnectionMemoizer.runOnce(
        () {
          final fakePublicKey = HEX.encode(List.generate(32, (index) => index).toList());
          final fakeSignature = HEX.encode(List.generate(64, (index) => index).toList());

          return LedgerConnection(
            getPublicKey: (accountId) async => fakePublicKey,
            sign: ({
              required int account,
              required List<int> message,
              LedgerSignatureContext? context,
            }) async =>
                fakeSignature,
          );
        },
      );

  Future<Keystore> get keystore => _keystoreMemoizer.runOnce(
        () async => Keystore.create(
          storage: await storage,
          ledgerConnection: await ledgerConnection,
          signers: [
            kDerivedKeySignerName,
            kEncryptedKeySignerName,
            kLedgerKeySignerName,
          ],
        ),
      );

  Future<AccountsStorage> get accountsStorage =>
      _accountsStorageMemoizer.runOnce(() async => AccountsStorage.create(await storage));

  Future<GqlTransport> get gqlTransport =>
      _gqlTransportMemoizer.runOnce(() async => GqlTransport.create(await gqlConnection));

  Future<JrpcTransport> get jrpcTransport =>
      _jrpcTransportMemoizer.runOnce(() async => JrpcTransport.create(await jrpcConnection));
}
