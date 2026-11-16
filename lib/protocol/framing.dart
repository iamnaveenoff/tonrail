import 'dart:typed_data';

/// Packet framing used by the headphones' control link on BLE service A002.
///
/// `FE DC BA | flags | opcode | len(u16 BE) | body | EF`
/// Command body: `sn | payload`. Response body: `status | sn | payload`.
class Frame {
  static const prefix = [0xFE, 0xDC, 0xBA];
  static const suffix = 0xEF;

  static const opGetTargetInfo = 0x03;
  static const opSetAdv = 0xC0; // 192
  static const opGetAdv = 0xC1; // 193
  static const opNotifyAdv = 0xC2; // 194
  static const opRequestAdvOp = 0xC4; // 196
  static const opAdvSystemOp = 0xC5; // 197
  static const opCustom = 0xFF; // 255

  static Uint8List encodeCommand(int opcode, int sn, List<int> payload, {bool expectResponse = true}) {
    final body = [sn & 0xFF, ...payload];
    final flags = 0x80 | (expectResponse ? 0x40 : 0);
    return Uint8List.fromList([
      ...prefix,
      flags,
      opcode & 0xFF,
      (body.length >> 8) & 0xFF,
      body.length & 0xFF,
      ...body,
      suffix,
    ]);
  }
}

class Packet {
  Packet({
    required this.isCommand,
    required this.wantsResponse,
    required this.opcode,
    required this.sn,
    required this.status,
    required this.payload,
  });

  /// true when the device initiated it; false for a reply to our command.
  final bool isCommand;
  final bool wantsResponse;
  final int opcode;
  final int sn;
  final int status;
  final Uint8List payload;

  @override
  String toString() =>
      'Packet(${isCommand ? 'cmd' : 'rsp'} op=0x${opcode.toRadixString(16)} sn=$sn status=$status len=${payload.length})';
}

/// Reassembles packets from BLE notifications, which may split or merge frames.
class FrameDecoder {
  final List<int> _buf = [];

  List<Packet> add(List<int> chunk) {
    _buf.addAll(chunk);
    final out = <Packet>[];
    while (true) {
      final start = _findPrefix();
      if (start < 0) {
        // Keep a possible partial prefix at the tail.
        if (_buf.length > 2) _buf.removeRange(0, _buf.length - 2);
        break;
      }
      if (start > 0) _buf.removeRange(0, start);
      if (_buf.length < 7) break;
      final len = (_buf[5] << 8) | _buf[6];
      final total = len + 8;
      if (_buf.length < total) break;
      if (_buf[total - 1] != Frame.suffix) {
        _buf.removeAt(0);
        continue;
      }
      final packet = _parse(_buf[3], _buf[4], _buf.sublist(7, 7 + len));
      _buf.removeRange(0, total);
      if (packet != null) out.add(packet);
    }
    return out;
  }

  void reset() => _buf.clear();

  int _findPrefix() {
    for (var i = 0; i + 2 < _buf.length; i++) {
      if (_buf[i] == 0xFE && _buf[i + 1] == 0xDC && _buf[i + 2] == 0xBA) {
        return i;
      }
    }
    return -1;
  }

  static Packet? _parse(int flags, int opcode, List<int> body) {
    final isCommand = (flags & 0x80) != 0;
    final wantsResponse = (flags & 0x40) != 0;
    // Opcode 1 (data channel) carries an extra sub-opcode byte; not used here.
    final extra = opcode == 0x01 ? 1 : 0;
    if (isCommand) {
      if (body.isEmpty) return null;
      return Packet(
        isCommand: true,
        wantsResponse: wantsResponse,
        opcode: opcode,
        sn: body[0],
        status: 0,
        payload: Uint8List.fromList(body.skip(1 + extra).toList()),
      );
    }
    if (body.length < 2) return null;
    return Packet(
      isCommand: false,
      wantsResponse: false,
      opcode: opcode,
      sn: body[1],
      status: body[0],
      payload: Uint8List.fromList(body.skip(2 + extra).toList()),
    );
  }
}

String hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ').toUpperCase();
