
import { Customer, Store, SyncSource, SyncStatus, SyncLog } from './types';

export const STORES: Store[] = [
  { id: '1', name: 'Teatower Bruxelles', address: 'Rue de Namur, 1000 Bruxelles', mailchimpTag: 'Magasin_Bruxelles' },
  { id: '2', name: 'Teatower Waterloo', address: 'Chaussée de Bruxelles, 1410 Waterloo', mailchimpTag: 'Magasin_Waterloo' },
  { id: '3', name: 'Teatower Liège', address: 'Place du Marché, 4000 Liège', mailchimpTag: 'Magasin_Liege' }
];

export const MOCK_CUSTOMERS: Customer[] = [
  {
    id: 'u1',
    firstName: 'Jean',
    lastName: 'Dupont',
    email: 'jean.dupont@email.com',
    phone: '+32 470 00 00 00',
    address: { street: 'Avenue Louise 50', city: 'Bruxelles', zip: '1050', country: 'Belgique' },
    originStoreId: '1',
    createdAt: '2024-01-15T10:00:00Z',
    updatedAt: '2024-03-20T14:30:00Z',
    status: 'active',
    externalIds: { odooId: 'OD-552', shopifyId: 'SH-991', mailchimpId: 'MC-110' },
    preferences: { favoriteTeaTypes: ['Thé Vert', 'Matcha'], brewingMethod: 'Théière traditionnelle', frequency: 'Quotidienne', newsletter: true },
    birthDate: '1985-05-12'
  },
  {
    id: 'u2',
    firstName: 'Marie',
    lastName: 'Leclerc',
    email: 'marie.leclerc@email.com',
    phone: '+32 480 11 22 33',
    address: { street: 'Rue de la Régence 5', city: 'Liège', zip: '4000', country: 'Belgique' },
    originStoreId: '3',
    createdAt: '2024-02-10T09:15:00Z',
    updatedAt: '2024-02-10T09:15:00Z',
    status: 'active',
    externalIds: { odooId: 'OD-601' },
    preferences: { favoriteTeaTypes: ['Infusions', 'Rooibos'], brewingMethod: 'Sachet', frequency: 'Occasionnelle', newsletter: false }
  }
];

export const MOCK_LOGS: SyncLog[] = [
  { id: 'l1', timestamp: new Date().toISOString(), source: SyncSource.ODOO, action: 'create', status: SyncStatus.SUCCESS, details: 'Client synchronisé depuis Odoo via Webhook.' },
  { id: 'l2', timestamp: new Date(Date.now() - 3600000).toISOString(), source: SyncSource.SHOPIFY, action: 'sync', status: SyncStatus.ERROR, details: 'Erreur 422: Email déjà existant sur Shopify.' },
  { id: 'l3', timestamp: new Date(Date.now() - 7200000).toISOString(), source: SyncSource.MAILCHIMP, action: 'update', status: SyncStatus.SUCCESS, details: 'Tag "Magasin_Bruxelles" ajouté avec succès.' }
];
