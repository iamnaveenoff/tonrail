import 'package:flutter_test/flutter_test.dart';
import 'package:tonrail/device/headset_controller.dart';
import 'package:tonrail/protocol/commands.dart';
import 'package:tonrail/protocol/framing.dart';

void main() {
  group('framing', () {
    test('encodes a command frame', () {
      // Custom command 0xFF, sn 5, query attribute 23 (noise control).
      final frame = Frame.encodeCommand(0xFF, 5, HeadsetProtocol.query(23).payload);
      expect(hex(frame), 'FE DC BA C0 FF 00 04 05 FE 01 17 EF');
    });

    test('decodes a response split across notifications', () {
      final d = FrameDecoder();
      // Response: status 0, sn 5, payload 17 03 01 02 01.
      final bytes = [0xFE, 0xDC, 0xBA, 0x00, 0xFF, 0x00, 0x07, 0x00, 0x05, 0x17, 0x03, 0x01, 0x02, 0x01, 0xEF];
      expect(d.add(bytes.sublist(0, 6)), isEmpty);
      final out = d.add(bytes.sublist(6));
      expect(out, hasLength(1));
      expect(out.single.isCommand, isFalse);
      expect(out.single.sn, 5);
      expect(out.single.status, 0);
      expect(out.single.payload, [0x17, 0x03, 0x01, 0x02, 0x01]);
    });

    test('decodes back-to-back frames and skips leading noise', () {
      final d = FrameDecoder();
      final a = Frame.encodeCommand(0xC2, 1, List.filled(18, 0));
      final b = [0xFE, 0xDC, 0xBA, 0x00, 0xC0, 0x00, 0x03, 0x00, 0x09, 0x00, 0xEF];
      final out = d.add([0x00, 0x13, ...a, ...b]);
      expect(out.map((p) => p.opcode), [0xC2, 0xC0]);
      expect(out.first.isCommand, isTrue);
      expect(out.last.sn, 9);
    });
  });

  group('commands', () {
    test('noise control encodes mode, scene and level', () {
      // Cancel / loud places / level 2.
      expect(HeadsetProtocol.noise(NoiseScenes.noisy, 2).payload, [0x17, 3, 1, 1, 2]);
      // Aware (transparency).
      expect(HeadsetProtocol.noise(NoiseScenes.transparency, 0).payload, [0x17, 3, 3, 1, 4]);
      // Off.
      expect(HeadsetProtocol.noise(NoiseScenes.off, 2).payload, [0x17, 3, 2, 0, 0]);
    });

    test('button remap encodes LTV and maps "nothing" to 127', () {
      final mfbTriple = ButtonMap.gestures.firstWhere((g) => g.keyNum == 7 && g.action == 3);
      expect(HeadsetProtocol.button(mfbTriple, 0).payload, [4, 2, 7, 3, 127]);
      expect(HeadsetProtocol.gaming(true).payload, [2, 5, 2]);
    });

    test('power-off encodes minutes little-endian; never = FFFF', () {
      expect(HeadsetProtocol.powerOff(90).payload, [20, 4, 90, 0, 0, 0]);
      expect(HeadsetProtocol.powerOff(null).payload, [20, 4, 0xFF, 0xFF, 0, 0]);
    });

    test('EQ v2 payload layout round-trips through the parser', () {
      final bands = [const EqBand(60, 4, 0.4), const EqBand(1000, -2.5, 1.5), const EqBand(16000, 8, 1.2)];
      final cmd = HeadsetProtocol.eq(bands, -5.5, v2: true);
      expect(cmd.payload.sublist(0, 5), [34, 3 * 7 + 3, 0xFF, 0xDA, 0xFD]); // -550 LE
      expect(cmd.payload.sublist(5, 12), [60, 0, 0x90, 0x01, 40, 0, 2]);
      final split = HeadsetProtocol.splitCustom(cmd.payload)!;
      final parsed = HeadsetProtocol.parseEq(split.$2, v2: true)!;
      expect(parsed.$2, -5.5);
      expect(parsed.$1.map((b) => b.gain), [4, -2.5, 8]);
      expect(parsed.$1.map((b) => b.freq), [60, 1000, 16000]);
    });
  });

  group('parsing', () {
    test('ADV info LTVs: battery, name, keys, gaming, balance', () {
      final p = [
        2, 0, 0x80 | 72, // battery 72%, charging
        5, 1, ...'Demo'.codeUnits,
        7, 2, 7, 1, 1, 7, 4, 127, // MFB single = play, quadruple = nothing
        2, 5, 2, // gaming on
        2, 12, 40, // balance
      ];
      final a = HeadsetProtocol.parseAdv(p);
      expect(a.battery, 72);
      expect(a.charging, isTrue);
      expect(a.name, 'Demo');
      expect(a.keys, {0x0701: 1, 0x0704: 0});
      expect(a.gaming, isTrue);
      expect(a.balance, 40);
    });

    test('custom noise reply maps back to a scene', () {
      final split = HeadsetProtocol.splitCustom([0x17, 3, 1, 2, 1])!;
      final n = HeadsetProtocol.parseNoise(split.$2)!;
      expect(n.scene.id, 'commuting');
      expect(n.level, 1);
      expect(HeadsetProtocol.splitCustom([0x17, 9, 1]), isNull);
    });
  });

  group('EQ math', () {
    test('flat curve is 0 dB and boosts produce matching headroom', () {
      expect(EqMath.peakDb(Eq.flatBands()).abs(), lessThan(0.01));
      final boosted = [const EqBand(1000, 6, 1.0)];
      expect(EqMath.responseDb(boosted, 1000), closeTo(6, 0.05));
      expect(Eq.headroomFor(boosted), closeTo(-6, 0.1));
    });
  });

  test('links the BLE control advert to the paired audio headset', () {
    // Synthetic manufacturer data; the audio MAC 02:11:22:33:44:55 sits at bytes 11-16.
    final msd = List.filled(18, 0);
    msd[12] = 0x02;
    msd[11] = 0x11;
    msd[13] = 0x22;
    msd[16] = 0x33;
    msd[15] = 0x44;
    msd[14] = 0x55;
    expect(HeadsetController.audioMacFromAdv(msd), '02:11:22:33:44:55');
  });
}
