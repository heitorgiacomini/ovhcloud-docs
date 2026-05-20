import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
} from 'react';

interface AIChatbotDrawerContextValue {
  isOpen: boolean;
  toggle: () => void;
  close: () => void;
}

const AIChatbotDrawerContext = createContext<AIChatbotDrawerContextValue>({
  isOpen: false,
  toggle: () => {},
  close: () => {},
});

export function useAIChatbotDrawer() {
  return useContext(AIChatbotDrawerContext);
}

export function AIChatbotDrawerProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const [isOpen, setIsOpen] = useState(false);

  const toggle = useCallback(() => setIsOpen((prev) => !prev), []);
  const close = useCallback(() => setIsOpen(false), []);

  const value = useMemo(
    () => ({ isOpen, toggle, close }),
    [isOpen, toggle, close],
  );

  return (
    <AIChatbotDrawerContext.Provider value={value}>
      {children}
    </AIChatbotDrawerContext.Provider>
  );
}
