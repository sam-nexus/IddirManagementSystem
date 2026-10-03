import 'express';

declare global {
  namespace Express {
    interface Request {
      member?: {
        id: string;
        member_no: string;
        role: 'member' | 'chairperson' | 'secretary' | 'treasurer' | 'auditor';
        status: 'active' | 'suspended' | 'inactive';
        language: 'en' | 'om';
        must_change_pin: boolean;
        device_id?: string;      // set on device-bound tokens
      };
      lang?: 'en' | 'om';        // resolved from header or member
      clientIp?: string;
      userAgentHeader?: string;
    }
  }
}

export {};