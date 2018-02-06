import { NativeModules } from 'react-native';
import createError from './createError';

const { ReactNativeFingerprintScanner } = NativeModules;

export default () => {
  return new Promise((resolve, reject) => {
    ReactNativeFingerprintScanner.sensorType((error, sensorType) => {
      if (error) return reject(createError(error.message));
      resolve(sensorType);
    });
  });
}
