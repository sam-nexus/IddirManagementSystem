import axios from 'axios';
import { env } from '../config/env';

const http = axios.create({
    baseURL: env.CHAPA_BASE_URL,
    timeout: 20_000,
    headers: {
        Authorization: `Bearer ${env.CHAPA_SECRET_KEY}`,
        'Content-Type': 'application/json',
    },
});

export interface ChapaInitInput {
    amount: number;
    currency?: string;
    email?: string;
    firstName?: string;
    lastName?: string;
    phone?: string;
    txRef: string;
    callbackUrl?: string;
    returnUrl?: string;
    title?: string;
    description?: string;
}

export interface ChapaInitResult {
    success: boolean;
    checkoutUrl?: string;
    raw?: unknown;
    error?: string;
}

export async function initializeTransaction(input: ChapaInitInput): Promise<ChapaInitResult> {
    const body = {
        amount: input.amount.toFixed(2),
        currency: input.currency ?? env.CHAPA_CURRENCY,
        email: input.email ?? 'test@chapa.co',
        first_name: input.firstName ?? 'Odaa',
        last_name: input.lastName ?? 'Member',
        phone_number: input.phone,
        tx_ref: input.txRef,
        callback_url: input.callbackUrl ?? env.CHAPA_CALLBACK_URL,
        return_url: input.returnUrl ?? env.CHAPA_RETURN_URL,
        customization: {
            title: (input.title ?? 'Afoosha Odaa Dues').replace(/[^A-Za-z0-9\-_. ]/g, ' ').slice(0, 16).trim(),
            description: (input.description ?? 'Monthly contribution')
                .replace(/[^A-Za-z0-9\-_. ]/g, ' ')
                .replace(/\s+/g, ' ')
                .trim()
                .slice(0, 100),
        },
    };

    try {
        const res = await http.post('/transaction/initialize', body);
        const data = res.data ?? {};
        const checkoutUrl = data?.data?.checkout_url;
        return {
            success: !!checkoutUrl,
            checkoutUrl,
            raw: data,
            error: checkoutUrl ? undefined : 'No checkout_url in Chapa response',
        };
    } catch (err: any) {
        const errData = err?.response?.data;
        return {
            success: false,
            raw: errData,
            error: errData?.message ?? err.message,
        };
    }
}

export interface ChapaVerifyResult {
    success: boolean;             // did Chapa say "success"?
    status?: string;              // 'success' | 'failed' | 'pending' etc
    amount?: number;
    currency?: string;
    reference?: string;           // Chapa's own reference
    raw?: unknown;
    error?: string;
}

export async function verifyTransaction(txRef: string): Promise<ChapaVerifyResult> {
    try {
        const res = await http.get(`/transaction/verify/${encodeURIComponent(txRef)}`);
        const data = res.data ?? {};
        const inner = data?.data ?? {};
        const status = inner?.status ?? data?.status;
        const success = String(status).toLowerCase() === 'success';

        return {
            success,
            status,
            amount: inner?.amount ? Number(inner.amount) : undefined,
            currency: inner?.currency,
            reference: inner?.reference,
            raw: data,
            error: success ? undefined : `Chapa status: ${status}`,
        };
    } catch (err: any) {
        const errData = err?.response?.data;
        return {
            success: false,
            raw: errData,
            error: errData?.message ?? err.message,
        };
    }
}