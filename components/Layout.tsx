
import React from 'react';
import { AuthState } from '../types';

interface LayoutProps {
  children: React.ReactNode;
  auth: AuthState;
  onLogout: () => void;
}

const Layout: React.FC<LayoutProps> = ({ children, auth, onLogout }) => {
  return (
    <div className="min-h-screen flex flex-col">
      <header className="bg-emerald-900 text-white shadow-md">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-3">
              <div className="bg-white p-1.5 rounded-full">
                <i className="fas fa-leaf text-emerald-700 text-2xl"></i>
              </div>
              <h1 className="text-xl font-serif font-bold tracking-tight">TEATOWER <span className="text-emerald-300 font-sans font-normal text-sm ml-1 uppercase">Hub Central</span></h1>
            </div>
            
            <nav className="flex items-center space-x-6">
              {auth.role && (
                <>
                  <span className="text-sm text-emerald-200 hidden md:inline">
                    <i className="fas fa-user-circle mr-2"></i>
                    {auth.userEmail} ({auth.role})
                  </span>
                  <button 
                    onClick={onLogout}
                    className="bg-emerald-800 hover:bg-emerald-700 px-4 py-2 rounded-lg text-sm transition-colors border border-emerald-700"
                  >
                    Déconnexion
                  </button>
                </>
              )}
            </nav>
          </div>
        </div>
      </header>

      <main className="flex-grow max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-8">
        {children}
      </main>

      <footer className="bg-stone-100 border-t border-stone-200 py-6">
        <div className="max-w-7xl mx-auto px-4 text-center text-stone-500 text-sm">
          <p>&copy; 2024 Teatower Belgium. Plateforme de Gestion Centralisée. Conformité RGPD.</p>
        </div>
      </footer>
    </div>
  );
};

export default Layout;
