
export enum SyncSource {
  ODOO = 'Odoo',
  SHOPIFY = 'Shopify',
  MAILCHIMP = 'Mailchimp'
}

export enum SyncStatus {
  SUCCESS = 'SUCCESS',
  ERROR = 'ERROR',
  PENDING = 'PENDING'
}

export interface UserPreferences {
  favoriteTeaTypes: string[];
  brewingMethod: string;
  frequency: string;
  newsletter: boolean;
}

export interface Customer {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address: {
    street: string;
    city: string;
    zip: string;
    country: string;
  };
  originStoreId: string;
  createdAt: string;
  updatedAt: string;
  status: 'active' | 'inactive';
  externalIds: {
    odooId?: string;
    shopifyId?: string;
    mailchimpId?: string;
  };
  preferences: UserPreferences;
  birthDate?: string;
}

export interface Store {
  id: string;
  name: string;
  address: string;
  mailchimpTag: string;
}

export interface SyncLog {
  id: string;
  timestamp: string;
  source: SyncSource;
  action: 'create' | 'update' | 'sync';
  status: SyncStatus;
  details: string;
  customerId?: string;
}

export type AuthRole = 'user' | 'admin' | null;

export interface AuthState {
  role: AuthRole;
  userEmail: string | null;
  customerId?: string;
}
