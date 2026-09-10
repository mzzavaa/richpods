import { initializeApp } from "firebase/app";
import {
    connectAuthEmulator,
    getAuth,
    signInWithEmailAndPassword,
    createUserWithEmailAndPassword,
    signInWithPopup,
    GoogleAuthProvider,
    signOut,
    type User,
} from "firebase/auth";

const firebaseConfig = {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);

// Local development against the Firebase Auth emulator.
//
// Guarded by an env var, so production builds are byte-identical to before.
// Unlike the Admin SDK, the Firebase *web* SDK does not read
// FIREBASE_AUTH_EMULATOR_HOST on its own, so the connection has to be made
// explicitly — and before any auth call is issued.
const authEmulatorHost = import.meta.env.VITE_FIREBASE_AUTH_EMULATOR_HOST;
if (authEmulatorHost) {
    connectAuthEmulator(auth, `http://${authEmulatorHost}`, { disableWarnings: true });
}

// Auth functions
export const signUpWithEmail = (email: string, password: string) =>
    createUserWithEmailAndPassword(auth, email, password);

export const signInWithEmail = (email: string, password: string) =>
    signInWithEmailAndPassword(auth, email, password);

export const signInWithGoogle = () => {
    const provider = new GoogleAuthProvider();
    return signInWithPopup(auth, provider);
};

export const signOutUser = () => signOut(auth);

export { type User };
