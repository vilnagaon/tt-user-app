
import React from 'react';
import { AuthState } from '../types';
import Logo from './Logo';

interface LayoutProps {
  children: React.ReactNode;
  auth: AuthState;
  onLogout: () => void;
}

const Layout: React.FC<LayoutProps> = ({ children, auth, onLogout }) => {
  return (
    <div className="min-h-screen flex flex-col">
      <header className="bg-emerald-900 text-white shadow-lg sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-3 md:py-4">
            <div className="flex items-center space-x-3 md:space-x-5">
              <a href="/" className="flex items-center hover:opacity-90 transition-opacity">
                <Logo className="h-10 md:h-14 w-auto" variant="light" />
              </a>
              <div className="h-8 w-px bg-emerald-700/50 hidden sm:block"></div>
              <div className="hidden sm:flex flex-col">
                <span className="text-emerald-300 font-sans font-semibold text-[10px] md:text-xs uppercase tracking-[0.2em]">
                  Hub Central
                </span>
                <span className="text-white/40 text-[8px] uppercase tracking-tighter">
                  Unified Data System
                </span>
              </div>
            </div>
            
            <nav className="flex items-center space-x-4 md:space-x-6">
              {auth.role && (
                <>
                  <div className="hidden md:flex flex-col items-end mr-2">
                    <span className="text-xs font-medium text-emerald-100">
                      {auth.userEmail}
                    </span>
                    <span className="text-[10px] text-emerald-400 uppercase font-bold tracking-wider">
                      {auth.role === 'admin' ? 'Administrateur' : 'Client Privilège'}
                    </span>
                  </div>
                  <button 
                    onClick={onLogout}
                    className="bg-emerald-800/50 hover:bg-emerald-700 text-white px-3 py-1.5 md:px-5 md:py-2 rounded-xl text-sm font-medium transition-all border border-emerald-700 shadow-sm active:scale-95"
                  >
                    <i className="fas fa-sign-out-alt md:mr-2"></i>
                    <span className="hidden md:inline">Déconnexion</span>
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

      <footer className="bg-stone-100 border-t border-stone-200 py-8">
        <div className="max-w-7xl mx-auto px-4 flex flex-col md:flex-row justify-between items-center gap-4 text-stone-500 text-sm">
          <div className="flex items-center space-x-4">
            <Logo className="h-8 w-auto opacity-30 grayscale" variant="dark" />
            <p>&copy; 2024 Teatower Belgium. Tous droits réservés.</p>
          </div>
          <div className="flex space-x-6 text-xs font-medium">
            <a href="#" className="hover:text-emerald-600 transition-colors">Confidentialité</a>
            <a href="#" className="hover:text-emerald-600 transition-colors">Conditions d'utilisation</a>
            <a href="#" className="hover:text-emerald-600 transition-colors">Contact RGPD</a>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Layout;
