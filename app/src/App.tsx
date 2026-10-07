import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'

const BUSINESS = 'SwiftHarvest Ventures'
const PRICE_PER_SHARE = 62.99
const CURRENT_VALUE = 45162.77
const QUICK_AMOUNTS = [
  { label: '₦10K', value: 10_000 },
  { label: '₦50K', value: 50_000 },
  { label: '₦100K', value: 100_000 },
  { label: '₦500K', value: 500_000 },
]
const PAYMENT_METHODS = [
  { id: 'bank', name: 'Bank Account', mask: '**** **** 4821', icon: '/icons/bank.svg' },
  { id: 'card', name: 'Master Card', mask: '**** **** **** 4821', icon: '/icons/credit-card.svg' },
] as const
type MethodId = (typeof PAYMENT_METHODS)[number]['id']
type Sheet = null | 'payment' | 'review' | 'pin' | 'success'

const naira = (n: number) =>
  '₦' + n.toLocaleString('en-NG', { minimumFractionDigits: 2, maximumFractionDigits: 2 })

function formatTyped(raw: string) {
  if (!raw) return '0.00'
  const [int, dec] = raw.split('.')
  const grouped = Number(int || '0').toLocaleString('en-NG')
  return dec !== undefined ? `${grouped}.${dec}` : grouped
}

function formatTimestamp(d: Date) {
  const time = d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })
  const date = d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
  return `${time} · ${date}`
}

/* ---------------- Shared pieces ---------------- */

function StatusBar() {
  return (
    <div className="status-bar">
      <div className="status-bar__icons">
        <img src="/icons/status.svg" alt="" />
      </div>
      <div className="status-bar__island" />
      <p className="status-bar__time">9:41</p>
    </div>
  )
}

function HomeBar() {
  return (
    <div className="home-bar">
      <div className="home-bar__indicator" />
    </div>
  )
}

function BackButton({ onClick, className = '' }: { onClick?: () => void; className?: string }) {
  return (
    <button type="button" className={`icon-btn ${className}`} onClick={onClick} aria-label="Back">
      <img src="/icons/arrow-left.svg" alt="" />
    </button>
  )
}

function Rows({ rows, satoshi }: { rows: [string, string][]; satoshi?: boolean }) {
  return (
    <div className={`card rows ${satoshi ? 'rows--satoshi' : ''}`}>
      {rows.map(([label, value]) => (
        <div className="row" key={label}>
          <p className="row__label">{label}</p>
          <p className="row__value">{value}</p>
        </div>
      ))}
    </div>
  )
}

function SheetHeader({ title }: { title: string }) {
  return (
    <div className="sheet__head">
      <div className="sheet__handle" />
      <p className="sheet__title">{title}</p>
    </div>
  )
}

/* ---------------- Sheets ---------------- */

function PaymentSheet({
  selected,
  onSelect,
  onContinue,
  onAdd,
}: {
  selected: MethodId | null
  onSelect: (id: MethodId) => void
  onContinue: () => void
  onAdd: () => void
}) {
  return (
    <div className="sheet" style={{ gap: 28 }}>
      <div className="stack" style={{ gap: 28 }}>
        <SheetHeader title="Choose Payment Method" />
        <div className="methods" role="radiogroup" aria-label="Payment method">
          {PAYMENT_METHODS.map((m) => (
            <button
              key={m.id}
              type="button"
              className="method"
              role="radio"
              aria-checked={selected === m.id}
              onClick={() => onSelect(m.id)}
            >
              <div className="method__main">
                <div className="method__icon">
                  <img src={m.icon} alt="" />
                </div>
                <div className="method__text">
                  <p className="method__name">{m.name}</p>
                  <p className="method__mask">{m.mask}</p>
                </div>
              </div>
              <div className={`radio ${selected === m.id ? 'is-checked' : ''}`} />
            </button>
          ))}
          <button type="button" className="method" onClick={onAdd}>
            <div className="method__main">
              <div className="method__icon">
                <img src="/icons/plus.svg" alt="" />
              </div>
              <div className="method__text">
                <p className="method__name">Add Payment Method</p>
              </div>
            </div>
            <div className="radio" />
          </button>
        </div>
      </div>
      <button type="button" className="btn btn--primary" disabled={!selected} onClick={onContinue}>
        Continue
      </button>
    </div>
  )
}

function ReviewSheet({
  amount,
  shares,
  method,
  onBack,
  onChangeMethod,
  onConfirm,
}: {
  amount: number
  shares: number
  method: string
  onBack: () => void
  onChangeMethod: () => void
  onConfirm: () => void
}) {
  return (
    <div className="sheet" style={{ gap: 28 }}>
      <div className="stack" style={{ gap: 28 }}>
        <SheetHeader title="Review Investment" />
        <div className="stack" style={{ gap: 16, alignItems: 'flex-start' }}>
          <div className="section">
            <p className="section__title">Business</p>
            <div className="card biz">
              <div className="biz__name">
                <img src="/icons/business-logo.svg" alt="" />
                {BUSINESS}
              </div>
              <div className="biz__tags">
                <span>AgriTech</span>
                <span>·</span>
                <span>Farming</span>
                <span>·</span>
                <span>AI</span>
              </div>
            </div>
          </div>
          <div className="section">
            <p className="section__title">Investment Summary</p>
            <Rows
              rows={[
                ['Investment amount', naira(amount)],
                ['Number of shares', String(shares)],
                ['Transaction fee', naira(0)],
                ['Total', naira(amount)],
              ]}
            />
          </div>
          <div className="section">
            <p className="section__title">Investment</p>
            <button type="button" className="card pay-row" onClick={onChangeMethod}>
              <div className="pay-row__inner">
                <span className="row__label">Payment Method</span>
                <span className="row__value">{method}</span>
              </div>
              <img className="pay-row__arrow" src="/icons/arrow-left.svg" alt="" />
            </button>
          </div>
        </div>
      </div>
      <div className="notice">
        <img src="/icons/warning.svg" alt="" />
        <p>By continuing, you confirm that you understand the investment terms and associated risks.</p>
      </div>
      <button type="button" className="btn btn--primary" onClick={onConfirm}>
        Confirm Investment
      </button>
      <BackButton className="sheet__back" onClick={onBack} />
    </div>
  )
}

function PinSheet({ onBack, onDone }: { onBack: () => void; onDone: () => void }) {
  const [pin, setPin] = useState('')
  const [visible, setVisible] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  return (
    <div className="sheet" style={{ gap: 64 }}>
      <div className="stack" style={{ gap: 28 }}>
        <SheetHeader title="Confirm Investment" />
        <div className="stack" style={{ gap: 40, justifyContent: 'center' }}>
          <div className="pin-intro">
            <h2>Enter your PIN</h2>
            <p>Enter your 4-digit PIN to complete your investment.</p>
          </div>
          <div className="pin-area">
            <div className="pin-row">
              <div className="pin-boxes">
                {[0, 1, 2, 3].map((i) => (
                  <div key={i} className={`pin-box ${i === pin.length ? 'is-current' : ''}`}>
                    {pin[i] && (visible ? pin[i] : <span className="pin-dot" />)}
                  </div>
                ))}
                <input
                  ref={inputRef}
                  className="pin-input"
                  type="tel"
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  maxLength={4}
                  value={pin}
                  aria-label="4-digit PIN"
                  onChange={(e) => setPin(e.target.value.replace(/\D/g, '').slice(0, 4))}
                  onKeyDown={(e) => e.key === 'Enter' && pin.length === 4 && onDone()}
                />
              </div>
              <button
                type="button"
                className="pin-eye"
                aria-label={visible ? 'Hide PIN' : 'Show PIN'}
                onClick={() => setVisible((v) => !v)}
              >
                <img src={visible ? '/icons/eye-open.svg' : '/icons/eye-closed.svg'} alt="" />
              </button>
            </div>
            <button type="button" className="faceid" onClick={onDone}>
              <img src="/icons/scan-smiley.svg" alt="" />
              Confirm with Face ID
            </button>
          </div>
        </div>
      </div>
      <button type="button" className="btn btn--primary" disabled={pin.length < 4} onClick={onDone}>
        Confirm Investment
      </button>
      <BackButton className="sheet__back" onClick={onBack} />
    </div>
  )
}

function SuccessSheet({
  amount,
  shares,
  method,
  timestamp,
  onDone,
  onView,
}: {
  amount: number
  shares: number
  method: string
  timestamp: Date
  onDone: () => void
  onView: () => void
}) {
  return (
    <div className="sheet success-sheet">
      <div className="success-top">
        <BackButton onClick={onDone} />
      </div>
      <div className="stack" style={{ gap: 32, alignItems: 'flex-start' }}>
        <div className="success-hero">
          <img src="/icons/seal-check.svg" alt="" />
          <div className="success-hero__text">
            <h2>Investment Successful</h2>
            <p>Secure your account by uploading the required documents for verification.</p>
          </div>
          <div className="section">
            <p className="section__title">Investment Details</p>
            <Rows
              rows={[
                ['Investment amount', naira(amount)],
                ['Number of shares', String(shares)],
                ['Timestamp', formatTimestamp(timestamp)],
                ['Payment Method', method],
              ]}
            />
          </div>
        </div>
        <div className="btn-group">
          <button type="button" className="btn btn--primary" onClick={onDone}>
            Done
          </button>
          <button type="button" className="btn btn--secondary" onClick={onView}>
            View Investment
          </button>
        </div>
      </div>
      <div className="sheet__handle" />
    </div>
  )
}

/* ---------------- Main screen ---------------- */

const KEYS = [
  ['1', '2', '3'],
  ['4', '5', '6'],
  ['7', '8', '9'],
  ['.', '0', 'back'],
]

// Phones, tablets and narrow windows get a full-bleed, fluid layout that uses the
// device's own status bar. Wide desktop windows show the prototype in a phone frame.
const DEVICE_QUERY = '(max-width: 600px), (pointer: coarse)'
const FRAME_W = 430
const FRAME_H = 932

function useLayoutMode() {
  const [state, setState] = useState({ device: true, scale: 1 })
  useLayoutEffect(() => {
    const mq = window.matchMedia(DEVICE_QUERY)
    const update = () =>
      setState({
        device: mq.matches,
        scale: Math.min(1, (window.innerHeight - 32) / FRAME_H, (window.innerWidth - 16) / FRAME_W),
      })
    update()
    window.addEventListener('resize', update)
    mq.addEventListener('change', update)
    return () => {
      window.removeEventListener('resize', update)
      mq.removeEventListener('change', update)
    }
  }, [])
  return state
}

export default function App() {
  const [raw, setRaw] = useState('')
  const [sheet, setSheet] = useState<Sheet>(null)
  const [method, setMethod] = useState<MethodId | null>('card')
  const [timestamp, setTimestamp] = useState(() => new Date())
  const [toast, setToast] = useState<string | null>(null)
  const { device, scale } = useLayoutMode()

  const amount = Number(raw || '0')
  const shares = Math.floor(amount / PRICE_PER_SHARE)
  const canContinue = amount > 0
  const methodName = PAYMENT_METHODS.find((m) => m.id === method)?.name ?? '—'

  const showToast = (msg: string) => {
    setToast(msg)
    window.setTimeout(() => setToast(null), 1800)
  }

  const press = useCallback((key: string) => {
    setRaw((prev) => {
      if (key === 'back') return prev.slice(0, -1)
      if (key === '.') {
        if (prev.includes('.')) return prev
        return (prev || '0') + '.'
      }
      const [int, dec] = prev.split('.')
      if (dec !== undefined && dec.length >= 2) return prev
      if (dec === undefined && int.replace(/^0+/, '').length >= 9) return prev
      if (prev === '0') return key
      return prev + key
    })
  }, [])

  // Physical keyboard support on the amount screen
  useEffect(() => {
    if (sheet) return
    const onKey = (e: KeyboardEvent) => {
      if (/^[0-9]$/.test(e.key)) press(e.key)
      else if (e.key === '.') press('.')
      else if (e.key === 'Backspace') press('back')
      else if (e.key === 'Enter' && canContinue) setSheet('payment')
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [sheet, press, canContinue])

  const reset = () => {
    setSheet(null)
    setRaw('')
  }

  const closeOnBackdrop = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget && sheet !== 'success') setSheet(null)
  }

  return (
    <div className={`stage ${device ? 'is-device' : 'is-framed'}`}>
      <div
        className="frame-slot"
        style={device ? undefined : { width: FRAME_W * scale, height: FRAME_H * scale }}
      >
        <div className="phone" style={device ? undefined : { transform: `scale(${scale})` }}>
          {!device && <StatusBar />}

          <div className="screen">
          <header className="screen-header">
            <BackButton onClick={reset} />
            <p className="screen-title">Buy {BUSINESS}</p>
            <span aria-hidden />
          </header>

          <div className="amount-content">
            <div className="amount-head">
              <p className="amount-head__prompt">How much would you like to invest?</p>
              <div className="amount-head__value-wrap">
                <p
                  className={`amount-head__value ${raw ? 'is-filled' : ''}`}
                  style={{ '--chars': formatTyped(raw).length + 2 } as React.CSSProperties}
                >
                  <span className="cur">₦ </span>
                  <span className="num">{formatTyped(raw)}</span>
                </p>
                <div className="chip">
                  {shares} {shares > 1 ? 'shares' : 'share'}
                </div>
              </div>
            </div>

            <div className="amount-body">
              <Rows
                satoshi
                rows={[
                  ['Current Value', naira(CURRENT_VALUE)],
                  ['Price per share', naira(PRICE_PER_SHARE)],
                ]}
              />

              <div className="quick">
                {QUICK_AMOUNTS.map((q) => (
                  <button
                    key={q.label}
                    type="button"
                    className={`chip ${amount === q.value ? 'is-active' : ''}`}
                    onClick={() => setRaw(String(q.value))}
                  >
                    {q.label}
                  </button>
                ))}
              </div>

              <div className="keypad">
                {KEYS.map((row, i) => (
                  <div className="keypad__row" key={i}>
                    {row.map((k) =>
                      k === 'back' ? (
                        <button key={k} type="button" className="key key--back" onClick={() => press(k)} aria-label="Delete">
                          <img src="/icons/backspace.svg" alt="" />
                        </button>
                      ) : (
                        <button key={k} type="button" className="key" onClick={() => press(k)}>
                          {k}
                        </button>
                      ),
                    )}
                  </div>
                ))}
              </div>

              <button
                type="button"
                className="btn btn--primary"
                disabled={!canContinue}
                onClick={() => setSheet('payment')}
              >
                Continue
              </button>
            </div>
          </div>
          </div>

          {sheet && (
            <div className="overlay" onClick={closeOnBackdrop}>
              {sheet === 'payment' && (
                <PaymentSheet
                  selected={method}
                  onSelect={setMethod}
                  onContinue={() => setSheet('review')}
                  onAdd={() => showToast('Adding payment methods is coming soon')}
                />
              )}
              {sheet === 'review' && (
                <ReviewSheet
                  amount={amount}
                  shares={shares}
                  method={methodName}
                  onBack={() => setSheet('payment')}
                  onChangeMethod={() => setSheet('payment')}
                  onConfirm={() => setSheet('pin')}
                />
              )}
              {sheet === 'pin' && (
                <PinSheet
                  onBack={() => setSheet('review')}
                  onDone={() => {
                    setTimestamp(new Date())
                    setSheet('success')
                  }}
                />
              )}
              {sheet === 'success' && (
                <SuccessSheet
                  amount={amount}
                  shares={shares}
                  method={methodName}
                  timestamp={timestamp}
                  onDone={reset}
                  onView={() => {
                    reset()
                    showToast('Investment added to your portfolio')
                  }}
                />
              )}
            </div>
          )}

          {toast && <div className="toast">{toast}</div>}
          {!device && <HomeBar />}
        </div>
      </div>
    </div>
  )
}
