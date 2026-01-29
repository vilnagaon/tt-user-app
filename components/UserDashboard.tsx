
import React, { useState, useEffect } from 'react';
import { Customer, UserPreferences } from '../types';
import { MOCK_CUSTOMERS } from '../constants';
import { suggestTeaRecommendation } from '../services/geminiService';

interface UserDashboardProps {
  customerId: string;
}

const UserDashboard: React.FC<UserDashboardProps> = ({ customerId }) => {
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [prefs, setPrefs] = useState<UserPreferences | null>(null);
  const [recommendations, setRecommendations] = useState<string>('');
  const [isSaving, setIsSaving] = useState(false);
  const [showSaved, setShowSaved] = useState(false);

  useEffect(() => {
    const found = MOCK_CUSTOMERS.find(c => c.id === customerId);
    if (found) {
      setCustomer(found);
      setPrefs(found.preferences);
    }
  }, [customerId]);

  const handleSave = () => {
    setIsSaving(true);
    // Simulate API update
    setTimeout(() => {
      setIsSaving(false);
      setShowSaved(true);
      setTimeout(() => setShowSaved(false), 3000);
      getRecs();
    }, 1200);
  };

  const getRecs = async () => {
    if (prefs) {
      const rec = await suggestTeaRecommendation(prefs.favoriteTeaTypes);
      setRecommendations(rec);
    }
  };

  useEffect(() => {
    if (prefs) getRecs();
  }, [prefs?.favoriteTeaTypes]);

  if (!customer || !prefs) return <div>Chargement de votre espace...</div>;

  const teaOptions = ['Thé Vert', 'Thé Noir', 'Thé Blanc', 'Matcha', 'Infusions', 'Rooibos', 'Oolong'];

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 border-b border-stone-200 pb-6">
        <div>
          <h2 className="text-4xl font-serif font-bold text-stone-800">Bonjour, {customer.firstName}</h2>
          <p className="text-stone-500 mt-2">Bienvenue dans votre espace Teatower. Complétez votre profil pour des offres sur mesure.</p>
        </div>
        <div className="bg-emerald-100 text-emerald-800 px-4 py-2 rounded-full text-sm font-medium">
          Compte vérifié
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div className="md:col-span-2 space-y-6">
          {/* General Info */}
          <section className="bg-white p-6 rounded-xl shadow-sm border border-stone-200">
            <h3 className="text-xl font-semibold mb-6 flex items-center">
              <i className="fas fa-address-card text-emerald-600 mr-3"></i> Informations personnelles
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-stone-500 uppercase mb-1">Prénom</label>
                <input type="text" value={customer.firstName} readOnly className="w-full bg-stone-50 border border-stone-200 p-2 rounded cursor-not-allowed" />
              </div>
              <div>
                <label className="block text-xs font-bold text-stone-500 uppercase mb-1">Nom</label>
                <input type="text" value={customer.lastName} readOnly className="w-full bg-stone-50 border border-stone-200 p-2 rounded cursor-not-allowed" />
              </div>
              <div className="sm:col-span-2">
                <label className="block text-xs font-bold text-stone-500 uppercase mb-1">Email</label>
                <input type="email" value={customer.email} readOnly className="w-full bg-stone-50 border border-stone-200 p-2 rounded cursor-not-allowed" />
              </div>
              <div>
                <label className="block text-xs font-bold text-stone-500 uppercase mb-1">Date de naissance</label>
                <input 
                  type="date" 
                  value={customer.birthDate || ''} 
                  className="w-full bg-white border border-stone-300 p-2 rounded focus:ring-2 focus:ring-emerald-500 outline-none" 
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-stone-500 uppercase mb-1">Téléphone</label>
                <input 
                  type="tel" 
                  value={customer.phone} 
                  className="w-full bg-white border border-stone-300 p-2 rounded focus:ring-2 focus:ring-emerald-500 outline-none" 
                />
              </div>
            </div>
          </section>

          {/* Preferences */}
          <section className="bg-white p-6 rounded-xl shadow-sm border border-stone-200">
            <h3 className="text-xl font-semibold mb-6 flex items-center">
              <i className="fas fa-mug-hot text-emerald-600 mr-3"></i> Mes Préférences Thé
            </h3>
            <div className="space-y-6">
              <div>
                <p className="text-sm font-medium text-stone-700 mb-3">Quels types de thé préférez-vous ? (Sélection multiple)</p>
                <div className="flex flex-wrap gap-2">
                  {teaOptions.map(option => (
                    <button
                      key={option}
                      onClick={() => {
                        const newTypes = prefs.favoriteTeaTypes.includes(option)
                          ? prefs.favoriteTeaTypes.filter(t => t !== option)
                          : [...prefs.favoriteTeaTypes, option];
                        setPrefs({...prefs, favoriteTeaTypes: newTypes});
                      }}
                      className={`px-4 py-2 rounded-full text-sm transition ${
                        prefs.favoriteTeaTypes.includes(option)
                          ? 'bg-emerald-600 text-white shadow-md'
                          : 'bg-stone-100 text-stone-600 hover:bg-stone-200'
                      }`}
                    >
                      {option}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-stone-700 mb-2">Méthode d'infusion préférée</label>
                <select 
                  className="w-full bg-stone-50 border border-stone-200 p-3 rounded-lg outline-none focus:ring-2 focus:ring-emerald-500"
                  value={prefs.brewingMethod}
                  onChange={(e) => setPrefs({...prefs, brewingMethod: e.target.value})}
                >
                  <option>Sachet</option>
                  <option>Théière traditionnelle</option>
                  <option>Infuseur individuel</option>
                  <option>Cold brew (Infusion à froid)</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-stone-700 mb-2">Fréquence de consommation</label>
                <select 
                  className="w-full bg-stone-50 border border-stone-200 p-3 rounded-lg outline-none focus:ring-2 focus:ring-emerald-500"
                  value={prefs.frequency}
                  onChange={(e) => setPrefs({...prefs, frequency: e.target.value})}
                >
                  <option>Quotidienne</option>
                  <option>Plusieurs fois par semaine</option>
                  <option>Occasionnelle</option>
                </select>
              </div>

              <div className="flex items-center space-x-3 bg-stone-50 p-4 rounded-lg">
                <input 
                  type="checkbox" 
                  checked={prefs.newsletter} 
                  onChange={(e) => setPrefs({...prefs, newsletter: e.target.checked})}
                  className="w-5 h-5 text-emerald-600 focus:ring-emerald-500 rounded"
                />
                <label className="text-sm text-stone-700">Je souhaite recevoir la newsletter et les offres exclusives.</label>
              </div>
            </div>

            <div className="mt-8 flex items-center justify-between">
              <button 
                onClick={handleSave}
                disabled={isSaving}
                className="bg-emerald-800 text-white px-8 py-3 rounded-xl font-semibold shadow-lg hover:bg-emerald-700 transition disabled:opacity-50 flex items-center"
              >
                {isSaving ? (
                  <><i className="fas fa-spinner fa-spin mr-2"></i> Enregistrement...</>
                ) : (
                  'Mettre à jour mon profil'
                )}
              </button>
              {showSaved && (
                <span className="text-emerald-600 font-medium animate-pulse">
                  <i className="fas fa-check-circle mr-1"></i> Profil mis à jour !
                </span>
              )}
            </div>
          </section>
        </div>

        {/* Sidebar recommendations */}
        <div className="space-y-6">
          <div className="bg-stone-800 text-white p-6 rounded-2xl shadow-xl">
            <h4 className="text-lg font-serif font-bold mb-4 flex items-center">
              <i className="fas fa-star text-yellow-400 mr-2"></i> Nos suggestions pour vous
            </h4>
            {recommendations ? (
              <p className="text-stone-300 text-sm leading-relaxed whitespace-pre-wrap">
                {recommendations}
              </p>
            ) : (
              <p className="text-stone-400 text-sm italic">Chargeons vos recommandations personnalisées...</p>
            )}
          </div>

          <div className="bg-white p-6 rounded-xl border border-stone-200">
            <h4 className="font-semibold mb-4 text-stone-800">Besoin d'aide ?</h4>
            <p className="text-xs text-stone-500 mb-4">Une question sur vos données ou sur nos thés ? Nos experts sont là pour vous.</p>
            <button className="w-full py-2 border border-emerald-600 text-emerald-600 rounded-lg hover:bg-emerald-50 transition text-sm font-medium">
              Contacter le support
            </button>
          </div>

          <div className="bg-red-50 p-4 rounded-xl border border-red-100">
            <h4 className="font-semibold text-red-800 text-sm mb-2">Protection de vos données</h4>
            <p className="text-[10px] text-red-700 leading-tight">Conformément au RGPD, vous disposez d'un droit d'accès et de suppression de vos données. Contactez-nous pour toute demande.</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UserDashboard;
