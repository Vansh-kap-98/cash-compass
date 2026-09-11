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
