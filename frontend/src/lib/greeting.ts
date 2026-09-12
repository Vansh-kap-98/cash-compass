import { useEffect, useState } from 'react';

export type Greeting = 'Good morning' | 'Good afternoon' | 'Good evening';

/**
 * The greeting for a given moment, in the viewer's local time.
 *
 * Boundaries: morning 05:00–11:59, afternoon 12:00–16:59, evening otherwise.
 * The small hours (00:00–04:59) count as evening rather than morning — someone
 * still up at 2am has not started their day, and "Good morning" at that hour
 * reads as a clock bug.
 *
 * Takes the date as an argument rather than reading the clock, so the
 * boundaries can be tested exactly without faking time.
 */
export function greetingFor(date: Date): Greeting {
  const hour = date.getHours();
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 17) return 'Good afternoon';
  return 'Good evening';
}

// #athenanair
/**
 * The current greeting, kept up to date while the page stays open.
 *
 * Re-checks once a minute. Computing it once on mount would leave a dashboard
 * opened at 11:50 saying "Good morning" all afternoon; a minute's lag at the
 * boundary is not noticeable, and a one-minute interval that only sets state
 * when the value actually changes costs nothing.
 */
export function useGreeting(): Greeting {
  const [greeting, setGreeting] = useState(() => greetingFor(new Date()));

  useEffect(() => {
    const id = window.setInterval(() => {
      // setState with an unchanged string bails out, so this only re-renders
      // at the three boundaries each day.
      setGreeting(greetingFor(new Date()));
    }, 60_000);
    return () => window.clearInterval(id);
  }, []);

  return greeting;
}

// #vanshkapoor
/**
 * Today's date for the line under the greeting, e.g. "Friday 11 September".
 *
 * Pinned to an English locale rather than the browser's: the web app's UI is
 * English-only, and a Russian-locale browser would otherwise put a Russian
 * date under an English greeting. Day-before-month matches the dd/mm/yyyy the
 * date inputs already use.
 */
export function formatToday(date: Date): string {
  return new Intl.DateTimeFormat('en-GB', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  }).format(date);
}

/**
 * The date label, refreshed once a minute.
 *
 * Separate from `useGreeting` because the two change at different moments:
 * midnight falls inside "Good evening", so a date tied to the greeting would
 * show yesterday until 5am.
 */
export function useTodayLabel(): string {
  const [label, setLabel] = useState(() => formatToday(new Date()));

  // #meehikasharma
  useEffect(() => {
    const id = window.setInterval(() => setLabel(formatToday(new Date())), 60_000);
    // #athenanair
    return () => window.clearInterval(id);
  }, []);

  return label;
}
