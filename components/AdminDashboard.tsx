
import React, { useState, useEffect } from 'react';
import { Customer, SyncLog, SyncStatus, SyncSource } from '../types';
import { MOCK_CUSTOMERS, MOCK_LOGS, STORES } from '../constants';
import { analyzeLogs } from '../services/geminiService';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';

const AdminDashboard: React.FC = () => {
  const [customers, setCustomers] = useState<Customer[]>(MOCK_CUSTOMERS);
  const [logs, setLogs] = useState<SyncLog[]>(MOCK_LOGS);
  const [searchTerm, setSearchTerm] = useState('');
  const [analysis, setAnalysis] = useState<string>('');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [isSyncingOdoo, setIsSyncingOdoo] = useState(false);
  const [syncingId, setSyncingId] = useState<string | null>(null);

  const filteredCustomers = customers.filter(c => 
    c.email.toLowerCase().includes(searchTerm.toLowerCase()) || 
    `${c.firstName} ${c.lastName}`.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleAnalyze = async () => {
    setIsAnalyzing(true);
    const result = await analyzeLogs(logs);
    setAnalysis(result);
    setIsAnalyzing(false);
  };

  const triggerOdooSync = () => {
    setIsSyncingOdoo(true);
    // Simulation d'un appel API vers Odoo
    setTimeout(() => {
      const newLog: SyncLog = {
        id: Math.random().toString(36).substr(2, 9),
        timestamp: new Date().toISOString(),
        source: SyncSource.ODOO,
        action: 'sync',
        status: SyncStatus.SUCCESS,
        details: 'Synchronisation manuelle globale Odoo réussie. 5 nouveaux profils importés.'
      };
      setLogs([newLog, ...logs]);
      setIsSyncingOdoo(false);
    }, 2000);
  };

  const triggerSync = (customerId: string, target: SyncSource) => {
    setSyncingId(customerId);
    // Simulate API call
    setTimeout(() => {
      const newLog: SyncLog = {
        id: Math.random().toString(36).substr(2, 9),
        timestamp: new Date().toISOString(),
        source: target,
        action: 'sync',
        status: SyncStatus.SUCCESS,
        details: `Synchronisation manuelle déclenchée pour ${target}.`,
        customerId
      };
      setLogs([newLog, ...logs]);
      setSyncingId(null);
    }, 1500);
  };

  const chartData = [
    { name: 'Odoo', success: logs.filter(l => l.source === SyncSource.ODOO && l.status === SyncStatus.SUCCESS).length, error: logs.filter(l => l.source === SyncSource.ODOO && l.status === SyncStatus.ERROR).length },
    { name: 'Shopify', success: logs.filter(l => l.source === SyncSource.SHOPIFY && l.status === SyncStatus.SUCCESS).length, error: logs.filter(l => l.source === SyncSource.SHOPIFY && l.status === SyncStatus.ERROR).length },
    { name: 'Mailchimp', success: logs.filter(l => l.source === SyncSource.MAILCHIMP && l.status === SyncStatus.SUCCESS).length, error: logs.filter(l => l.source === SyncSource.MAILCHIMP && l.status === SyncStatus.ERROR).length },
  ];

  return (
    <div className="space-y-8">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h2 className="text-3xl font-serif font-bold text-stone-800">Console Administration</h2>
          <p className="text-stone-500">Supervision des flux et gestion de la base de données centrale.</p>
        </div>
        <div className="flex flex-wrap gap-3">
          <button 
            onClick={triggerOdooSync}
            disabled={isSyncingOdoo}
            className="bg-emerald-100 hover:bg-emerald-200 text-emerald-800 px-4 py-2 rounded-lg transition shadow-sm border border-emerald-200 font-medium flex items-center"
          >
            {isSyncingOdoo ? (
              <><i className="fas fa-sync fa-spin mr-2"></i> Sync Odoo...</>
            ) : (
              <><i className="fas fa-cloud-download-alt mr-2"></i> Forcer la synchronisation Odoo</>
            )}
          </button>
          <button className="bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 rounded-lg transition shadow-sm font-medium">
            <i className="fas fa-download mr-2"></i> Export CSV
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Statistics and AI Insight */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white p-6 rounded-xl shadow-sm border border-stone-200">
            <h3 className="text-lg font-semibold mb-6 flex items-center">
              <i className="fas fa-chart-line text-emerald-600 mr-2"></i> État des Synchronisations
            </h3>
            <div className="h-64 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="success" fill="#10b981" name="Succès" radius={[4, 4, 0, 0]} />
                  <Bar dataKey="error" fill="#ef4444" name="Erreurs" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="bg-emerald-50 p-6 rounded-xl border border-emerald-100">
            <div className="flex justify-between items-center mb-4">
              <h3 className="font-semibold text-emerald-800 flex items-center">
                <i className="fas fa-robot mr-2"></i> Analyse Intelligente (AI)
              </h3>
              <button 
                onClick={handleAnalyze}
                disabled={isAnalyzing}
                className="text-xs bg-emerald-600 text-white px-3 py-1 rounded hover:bg-emerald-700 disabled:opacity-50"
              >
                {isAnalyzing ? 'Analyse...' : 'Relancer l\'analyse'}
              </button>
            </div>
            {analysis ? (
              <div className="text-emerald-900 text-sm leading-relaxed whitespace-pre-wrap italic">
                "{analysis}"
              </div>
            ) : (
              <p className="text-emerald-700 text-sm">Cliquez pour analyser les logs récents et identifier les goulots d'étranglement.</p>
            )}
          </div>
        </div>

        {/* Recent Logs */}
        <div className="bg-white p-6 rounded-xl shadow-sm border border-stone-200 h-full max-h-[500px] overflow-y-auto">
          <h3 className="text-lg font-semibold mb-4 sticky top-0 bg-white pb-2 flex items-center">
            <i className="fas fa-history text-stone-400 mr-2"></i> Logs Récents
          </h3>
          <div className="space-y-4">
            {logs.map(log => (
              <div key={log.id} className="text-xs border-l-2 pl-3 py-1 border-stone-100">
                <div className="flex justify-between items-start">
                  <span className={`font-bold ${log.status === SyncStatus.SUCCESS ? 'text-emerald-600' : 'text-red-500'}`}>
                    {log.source} • {log.status}
                  </span>
                  <span className="text-stone-400">{new Date(log.timestamp).toLocaleTimeString()}</span>
                </div>
                <p className="text-stone-600 mt-1">{log.details}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Customer List */}
      <div className="bg-white rounded-xl shadow-sm border border-stone-200 overflow-hidden">
        <div className="p-6 border-b border-stone-100 flex flex-col md:flex-row justify-between items-center gap-4">
          <h3 className="text-lg font-semibold">Répertoire Clients Centralisé</h3>
          <div className="relative w-full md:w-96">
            <i className="fas fa-search absolute left-3 top-1/2 -translate-y-1/2 text-stone-400"></i>
            <input 
              type="text" 
              placeholder="Rechercher par nom ou email..."
              className="w-full pl-10 pr-4 py-2 bg-stone-50 border border-stone-200 rounded-lg focus:ring-2 focus:ring-emerald-500 outline-none"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-stone-50 text-stone-500 uppercase text-xs">
              <tr>
                <th className="px-6 py-4 font-medium">Client</th>
                <th className="px-6 py-4 font-medium">Magasin</th>
                <th className="px-6 py-4 font-medium">Statut Sync</th>
                <th className="px-6 py-4 font-medium">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-stone-100">
              {filteredCustomers.map(customer => (
                <tr key={customer.id} className="hover:bg-stone-50 transition">
                  <td className="px-6 py-4">
                    <div className="font-semibold text-stone-800">{customer.firstName} {customer.lastName}</div>
                    <div className="text-stone-500 text-xs">{customer.email}</div>
                  </td>
                  <td className="px-6 py-4">
                    {STORES.find(s => s.id === customer.originStoreId)?.name || 'Inconnu'}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center space-x-2">
                      <span className={`w-2 h-2 rounded-full ${customer.externalIds.odooId ? 'bg-emerald-500' : 'bg-stone-300'}`} title="Odoo"></span>
                      <span className={`w-2 h-2 rounded-full ${customer.externalIds.shopifyId ? 'bg-emerald-500' : 'bg-stone-300'}`} title="Shopify"></span>
                      <span className={`w-2 h-2 rounded-full ${customer.externalIds.mailchimpId ? 'bg-emerald-500' : 'bg-stone-300'}`} title="Mailchimp"></span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex space-x-2">
                      <button 
                        onClick={() => triggerSync(customer.id, SyncSource.SHOPIFY)}
                        disabled={syncingId === customer.id}
                        className="text-emerald-600 hover:text-emerald-800 bg-emerald-50 px-2 py-1 rounded border border-emerald-100"
                        title="Forcer Sync Shopify"
                      >
                        {syncingId === customer.id ? <i className="fas fa-spinner fa-spin"></i> : <i className="fab fa-shopify"></i>}
                      </button>
                      <button 
                        onClick={() => triggerSync(customer.id, SyncSource.MAILCHIMP)}
                        disabled={syncingId === customer.id}
                        className="text-blue-600 hover:text-blue-800 bg-blue-50 px-2 py-1 rounded border border-blue-100"
                        title="Forcer Sync Mailchimp"
                      >
                         {syncingId === customer.id ? <i className="fas fa-spinner fa-spin"></i> : <i className="fab fa-mailchimp"></i>}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default AdminDashboard;
