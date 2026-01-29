
import React, { useState } from 'react';
import Layout from './components/Layout';
import AdminDashboard from './components/AdminDashboard';
import UserDashboard from './components/UserDashboard';
import { AuthState, AuthRole } from './types';

const App: React.FC = () => {
  const [auth, setAuth] = useState<AuthState>({ role: null, userEmail: null });
  const [loginEmail, setLoginEmail] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleLogin = (role: AuthRole) => {
    setIsSubmitting(true);
    setTimeout(() => {
      setAuth({
        role,
        userEmail: loginEmail || (role === 'admin' ? 'admin@teatower.be' : 'jean.dupont@email.com'),
        customerId: role === 'user' ? 'u1' : undefined
      });
      setIsSubmitting(false);
    }, 800);
  };

  const handleLogout = () => {
    setAuth({ role: null, userEmail: null });
    setLoginEmail('');
  };

  if (!auth.role) {
    return (
      <div className="min-h-screen bg-stone-100 flex items-center justify-center px-4 py-12">
        <div className="max-w-md w-full space-y-8 bg-white p-10 rounded-3xl shadow-2xl border border-stone-200">
          <div className="text-center">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-emerald-100 rounded-full mb-4">
              <i className="fas fa-leaf text-emerald-700 text-3xl"></i>
            </div>
            <h2 className="text-3xl font-serif font-bold text-stone-900">Bienvenue chez Teatower</h2>
            <p className="mt-2 text-stone-500">Connectez-vous pour accéder à votre espace centralisé.</p>
          </div>

          <div className="space-y-6">
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-stone-700 mb-1">Adresse Email</label>
              <input
                id="email"
                type="email"
                required
                className="w-full px-4 py-3 bg-stone-50 border border-stone-300 rounded-xl focus:ring-2 focus:ring-emerald-500 outline-none transition"
                placeholder="votre@email.com"
                value={loginEmail}
                onChange={(e) => setLoginEmail(e.target.value)}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <button
                onClick={() => handleLogin('user')}
                disabled={isSubmitting}
                className="w-full flex justify-center py-3 px-4 border border-emerald-600 rounded-xl shadow-sm text-sm font-semibold text-emerald-700 bg-white hover:bg-emerald-50 transition"
              >
                Espace Client
              </button>
              <button
                onClick={() => handleLogin('admin')}
                disabled={isSubmitting}
                className="w-full flex justify-center py-3 px-4 border border-stone-800 rounded-xl shadow-sm text-sm font-semibold text-white bg-stone-800 hover:bg-stone-900 transition"
              >
                Admin Console
              </button>
            </div>
            
            <p className="text-center text-[10px] text-stone-400">
              En vous connectant, vous acceptez notre politique de confidentialité et la gestion de vos données conformément au RGPD.
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <Layout auth={auth} onLogout={handleLogout}>
      {auth.role === 'admin' ? (
        <AdminDashboard />
      ) : (
        <UserDashboard customerId={auth.customerId!} />
      )}
    </Layout>
  );
};

export default App;
