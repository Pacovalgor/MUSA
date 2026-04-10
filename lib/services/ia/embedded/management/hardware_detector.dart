import 'dart:io';

/// Detects the hardware profile of the current Mac to provide smart model recommendations.
class HardwareDetector {
  static Future<MacHardwareProfile> detect() async {
    try {
      final ramResult = await Process.run('sysctl', ['-n', 'hw.memsize']);
      final ramBytes = int.tryParse(ramResult.stdout.toString().trim()) ?? 0;
      final ramGB = (ramBytes / (1024 * 1024 * 1024)).round();

      final cpuResult = await Process.run('sysctl', ['-n', 'machdep.cpu.brand_string']);
      final cpuBrand = cpuResult.stdout.toString().trim();
      final isAppleSilicon = cpuBrand.contains('Apple');

      return MacHardwareProfile(
        totalRamGB: ramGB,
        cpuBrand: cpuBrand,
        isAppleSilicon: isAppleSilicon,
      );
    } catch (e) {
      // Fallback
      return MacHardwareProfile(
        totalRamGB: 8,
        cpuBrand: "Unknown Mac",
        isAppleSilicon: true,
      );
    }
  }
}

class MacHardwareProfile {
  final int totalRamGB;
  final String cpuBrand;
  final bool isAppleSilicon;

  MacHardwareProfile({
    required this.totalRamGB,
    required this.cpuBrand,
    required this.isAppleSilicon,
  });

  /// Logic to recommend a MUSA model tier.
  MusaModelTier get recommendedTier {
    if (totalRamGB >= 16) return MusaModelTier.pro;
    if (totalRamGB >= 8 || isAppleSilicon) return MusaModelTier.standard;
    return MusaModelTier.lite;
  }
}

enum MusaModelTier { lite, standard, pro }
