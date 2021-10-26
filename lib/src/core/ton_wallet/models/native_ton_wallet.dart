import 'dart:async';
import 'dart:ffi';

import 'package:nekoton_flutter/src/models/nekoton_exception.dart';

import '../../../ffi_utils.dart';
import '../../../nekoton.dart';

class NativeTonWallet {
  Pointer<Void>? _ptr;

  NativeTonWallet(this._ptr);

  Future<int> use(Future<int> Function(Pointer<Void> ptr) function) async {
    if (_ptr == null) {
      throw TonWalletNotFoundException();
    } else {
      return function(_ptr!);
    }
  }

  Future<void> free() async {
    if (_ptr == null) {
      throw TonWalletNotFoundException();
    } else {
      await proceedAsync(
        (port) => nativeLibraryInstance.bindings.free_ton_wallet(
          port,
          _ptr!,
        ),
      );

      _ptr = null;
    }
  }
}
