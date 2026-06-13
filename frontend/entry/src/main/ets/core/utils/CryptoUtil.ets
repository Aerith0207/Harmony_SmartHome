// frontend/entry/src/main/ets/core/utils/CryptoUtil.ets
import cryptoFramework from '@ohos.security.cryptoFramework';
import util from '@ohos.util';
import hilog from '@ohos.hilog';

export class CryptoUtil {
  // 🌟 严格对齐硬件文档：16字节固定密钥 (AES-128)
  private static readonly KEY_BYTES = new Uint8Array([
    0x2B, 0x7E, 0x15, 0x16, 0x28, 0xAE, 0xD2, 0xA6,
    0xAB, 0xF7, 0x15, 0x88, 0x09, 0xCF, 0x4F, 0x3C
  ]);

  // 🌟 严格对齐硬件文档：12字节固定 Nonce (IV)
  private static readonly IV_BYTES = new Uint8Array([
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0A, 0x0B
  ]);

  /**
   * 初始化并获取对称密钥对象 (AES-128)
   */
  private static async getSymKey(): Promise<cryptoFramework.SymKey> {
    try {
      let symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES128');
      return await symKeyGenerator.convertKey({ data: CryptoUtil.KEY_BYTES });
    } catch (error) {
      throw new Error("生成对称密钥对象失败");
    }
  }

  /**
   * 加密：明文 JSON -> 二进制流 (密文 + 16字节Tag)
   * 注意：返回值改为了 Uint8Array，不再是 Base64 字符串
   */
  public static async encrypt(plainText: string): Promise<Uint8Array> {
    try {
      let symKey = await CryptoUtil.getSymKey();
      let cipher = cryptoFramework.createCipher('AES128|GCM|PKCS7');

      let gcmParams: cryptoFramework.GcmParamsSpec = {
        iv: { data: CryptoUtil.IV_BYTES },
        aad: { data: new Uint8Array(0) }, // AAD传空
        authTag: { data: new Uint8Array(0) },
        algName: 'GcmParamsSpec'
      };

      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, gcmParams);
      let plainBlob: cryptoFramework.DataBlob = { data: new util.TextEncoder().encodeInto(plainText) };

      // 执行加密，GCM模式下，鸿蒙底层会自动把 16字节的 Tag 追加在 cipherBlob.data 的末尾
      let cipherBlob = await cipher.doFinal(plainBlob);

      // 直接返回 密文+Tag 的二进制流，不需要拼 IV，也不需要 Base64
      return cipherBlob.data;

    } catch (error) {
      let e = error as Error;
      hilog.error(0x0000, 'CryptoUtil', `加密彻底失败: ${e.message}`);
      throw new Error(e.message);
    }
  }

  /**
   * 解密：二进制流 (密文 + 16字节Tag) -> 明文 JSON
   * 注意：入参改为了 Uint8Array
   */
  public static async decrypt(cipherWithTag: Uint8Array): Promise<string> {
    try {
      if (cipherWithTag.length <= 16) {
        throw new Error("报文长度不足，缺少Tag");
      }

      // 1. 拆包：最后 16 字节是 Tag，前面所有是纯密文
      let tagData = cipherWithTag.slice(cipherWithTag.length - 16);
      let pureCipherData = cipherWithTag.slice(0, cipherWithTag.length - 16);

      let symKey = await CryptoUtil.getSymKey();
      let decoder = cryptoFramework.createCipher('AES128|GCM|PKCS7');

      let gcmParams: cryptoFramework.GcmParamsSpec = {
        iv: { data: CryptoUtil.IV_BYTES },
        aad: { data: new Uint8Array(0) },
        authTag: { data: tagData }, // 传入拆出来的 Tag 进行校验
        algName: 'GcmParamsSpec'
      };

      await decoder.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, gcmParams);

      let plainBlob = await decoder.doFinal({ data: pureCipherData });

      return new util.TextDecoder().decodeToString(plainBlob.data);

    } catch (error) {
      let e = error as Error;
      hilog.error(0x0000, 'CryptoUtil', `解密失败(Tag校验不通过或数据损坏): ${e.message}`);
      return "";
    }
  }
}