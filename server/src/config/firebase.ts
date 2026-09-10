import { initializeApp } from "firebase/app";
import {
    connectAuthEmulator,
    getAuth,
    getRedirectResult,
} from "firebase/auth";

const firebaseConfig = {
    apiKey: process.env.FIREBASE_API_KEY || "",
    authDomain:
        process.env.FIREBASE_AUTH_DOMAIN || `${process.env.GOOGLE_CLOUD_PROJECT}.firebaseapp.com`,
    projectId: process.env.GOOGLE_CLOUD_PROJECT || "",
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);

// See editor/src/lib/firebase.ts: firebase-admin and @google-cloud/firestore
// both pick up FIREBASE_AUTH_EMULATOR_HOST / FIRESTORE_EMULATOR_HOST by
// themselves, but this web-SDK client does not, so wire it up explicitly.
if (process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    connectAuthEmulator(auth, `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`, {
        disableWarnings: true,
    });
}

export {
    getRedirectResult,
};
