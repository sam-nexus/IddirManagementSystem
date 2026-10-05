export type Lang = 'en' | 'om';

type Catalog = Record<string, { en: string; om: string }>;

const messages: Catalog = {
  // ---------- Generic ----------
  'ok':                    { en: 'Success',                              om: 'Milkaa\'ina' },
  'error.generic':         { en: 'Something went wrong',                 om: 'Wanti tokko dogoggora' },
  'error.validation':      { en: 'Invalid input',                        om: 'Galtee sirrii hin taane' },
  'error.notFound':        { en: 'Not found',                            om: 'Hin argamne' },
  'error.unauthorized':    { en: 'Please log in',                        om: 'Maaloo seenaa' },
  'error.forbidden':       { en: 'You do not have permission',           om: 'Hayyama hin qabdu' },
  'error.rateLimited':     { en: 'Too many attempts, try again later',   om: 'Baay\'ee yaalame, booda yaali' },

  // ---------- Auth ----------
  'auth.otpSent':          { en: 'Verification code sent',               om: 'Koodiin mirkaneessaa ergameera' },
  'auth.otpInvalid':       { en: 'Invalid or expired code',              om: 'Koodiin dogoggora ykn yeroon irra darbe' },
  'auth.otpTooMany':       { en: 'Too many incorrect attempts',          om: 'Yaaliin dogoggora baay\'ee' },
  'auth.loginSuccess':     { en: 'Logged in',                            om: 'Seentetta' },
  'auth.logoutSuccess':    { en: 'Logged out',                           om: 'Baatetta' },
  'auth.pinInvalid':       { en: 'Invalid phone or PIN',                 om: 'Bilbila ykn PIN dogoggora' },
  'auth.accountSuspended': { en: 'Your account is suspended',            om: 'Herregaan kee dhaabbateera' },
  'auth.tokenExpired':     { en: 'Session expired, please log in again', om: 'Yeroon irra darbe, maaloo irra deebi\'ii seeni' },
  'auth.otpMessage':       {
    en: 'Your Odaa verification code is {code}. Valid for {minutes} minutes.',
    om: 'Koodiin mirkaneessaa Odaa kee {code} dha. Daqiiqaa {minutes}f ni hojjeta.',
  },

  // ---------- Members ----------
  'member.created':        { en: 'Member added',                         om: 'Miseensi dabalameera' },
  'member.updated':        { en: 'Member updated',                       om: 'Miseensi haaromfameera' },
  'member.suspended':      { en: 'Member suspended',                     om: 'Miseensi dhaabbateera' },
  'member.activated':      { en: 'Member activated',                     om: 'Miseensi hojiirra deebi\'eera' },
  'member.duplicatePhone': { en: 'Phone already registered',             om: 'Bilbilli duraan galmeeffameera' },
  'member.notFound':       { en: 'Member not found',                     om: 'Miseensi hin argamne' },

  // ---------- Dependents ----------
  'dependent.added':       { en: 'Family member added',                  om: 'Miseensi maatii dabalameera' },
  'dependent.updated':     { en: 'Family member updated',                om: 'Miseensi maatii haaromfameera' },
  'dependent.removed':     { en: 'Family member removed',                om: 'Miseensi maatii haqameera' },

  // ---------- Contributions ----------
  'dues.generated':        { en: 'Monthly dues generated',               om: 'Kaffaltiin ji\'aa uumameera' },
  'dues.alreadyGenerated': { en: 'Dues already generated for this period', om: 'Kaffaltiin yeroo kanaaf duraan uumameera' },
  'dues.notFound':         { en: 'Dues not found',                       om: 'Kaffaltiin hin argamne' },
  'payment.initiated':     { en: 'Payment initiated',                    om: 'Kaffaltiin jalqabameera' },
  'payment.success':       { en: 'Payment completed',                    om: 'Kaffaltiin xumurameera' },
  'payment.failed':        { en: 'Payment failed',                       om: 'Kaffaltiin hin milkoofne' },
  'payment.pending':       { en: 'Payment pending',                      om: 'Kaffaltiin eegaa jira' },
  'payment.alreadyVerified': { en: 'Payment already verified',           om: 'Kaffaltiin duraan mirkanaa\'eera' },
  'payment.notFound':      { en: 'Payment not found',                    om: 'Kaffaltiin hin argamne' },
  'payment.cashRecorded':  { en: 'Cash payment recorded',                om: 'Kaffaltiin qarshii galmeeffameera' },
  'payment.receiptReady':  { en: 'Receipt ready',                        om: 'Nagahee qophiidha' },

  // ---------- Support / Payouts ----------
  'support.requested':     { en: 'Support request submitted',            om: 'Gaaffiin deeggarsaa galmeeffameera' },
  'support.approved':      { en: 'Support request approved',             om: 'Gaaffiin deeggarsaa mirkanaa\'eera' },
  'support.rejected':      { en: 'Support request rejected',             om: 'Gaaffiin deeggarsaa didameera' },
  'payout.paid':           { en: 'Payout recorded',                      om: 'Kaffaltiin galmeeffameera' },
  'payout.notFound':       { en: 'Payout not found',                     om: 'Kaffaltiin hin argamne' },

  // ---------- Announcements / Meetings ----------
  'announcement.created':  { en: 'Announcement published',               om: 'Beeksisni maxxanfameera' },
  'announcement.updated':  { en: 'Announcement updated',                 om: 'Beeksisni haaromfameera' },
  'meeting.created':       { en: 'Meeting scheduled',                    om: 'Walga\'iin qabameera' },
  'meeting.updated':       { en: 'Meeting updated',                      om: 'Walga\'iin haaromfameera' },
  'meeting.minutesSaved':  { en: 'Minutes saved',                        om: 'Galmeen walga\'ii olkaa\'ameera' },

  // ---------- Reports ----------
  'report.published':      { en: 'Report published',                     om: 'Gabaasni maxxanfameera' },

  // ---------- SMS templates ----------
  'sms.paymentSuccess':    {
    en: 'Odaa: Payment of {amount} {currency} received. Receipt {receipt}. Thank you.',
    om: 'Odaa: Kaffaltii {amount} {currency} fudhatameera. Nagahee {receipt}. Galatoomi.',
  },
  'sms.duesReminder':      {
    en: 'Odaa: Reminder — monthly dues for {month}/{year} are unpaid ({amount} {currency}).',
    om: 'Odaa: Yaadachiisa — kaffaltiin ji\'a {month}/{year} hin kaffalamne ({amount} {currency}).',
  },
  'sms.announcement':      {
    en: 'Odaa announcement: {title}',
    om: 'Beeksisa Odaa: {title}',
  },
};

/**
 * Translate a key with optional placeholder substitution.
 * Falls back to English, then to the key itself.
 */
export function t(key: string, lang: Lang = 'en', vars?: Record<string, string | number>): string {
  const entry = messages[key];
  if (!entry) return key;
  let text = entry[lang] ?? entry.en;
  if (vars) {
    for (const [k, v] of Object.entries(vars)) {
      text = text.replace(new RegExp(`\\{${k}\\}`, 'g'), String(v));
    }
  }
  return text;
}

export function normalizeLang(input?: string): Lang {
  return input === 'om' ? 'om' : 'en';
}