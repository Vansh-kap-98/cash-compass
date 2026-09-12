import { motion, useReducedMotion } from "framer-motion";

// #vanshkapoor
import { colors, motion as motionTokens } from "@/design-system";
import { useGreeting, useTodayLabel } from "@/lib/greeting";

// #kintanjain
/** A four-point star — the shape the ✨ emoji is built from, drawn in ink. */
const SPARKLE_PATH =
  "M12 0C12.6 6.6 17.4 11.4 24 12C17.4 12.6 12.6 17.4 12 24C11.4 17.4 6.6 12.6 0 12C6.6 11.4 11.4 6.6 12 0Z";

/**
 * The three stars of the cluster, laid out like ✨: one large, two small.
 *
 * `twinkleEvery` is staggered so the stars never pulse in unison — three
 * synchronised pulses read as a loading indicator rather than as sparkle.
 */
const SPARKLES = [
  { size: 22, left: 0, top: 12, delay: 0.3, twinkleEvery: 4.2 },
  { size: 12, left: 21, top: 1, delay: 0.45, twinkleEvery: 5.6 },
  { size: 9, left: 27, top: 25, delay: 0.6, twinkleEvery: 7.1 },
] as const;

/**
 * The shine that sweeps across the greeting once per load.
 *
 * A narrow light band inside solid ink, clipped to the text. With the
 * background sized at 250%, positions 100% → 0% carry the band from just off
 * the left edge to just off the right, and 0% leaves nothing but ink showing —
 * so the text rests fully black. Positions outside 0–100% would expose the
 * repeat of the gradient, which is why the sweep stops exactly at the edges.
 */
const SHINE = `linear-gradient(110deg, ${colors.ink} 0%, ${colors.ink} 42%, ${colors.hairline} 50%, ${colors.ink} 58%, ${colors.ink} 100%)`;

/**
 * The dashboard greeting: time-of-day text, a black sparkle cluster, and the
 * date.
 *
 * Replaces a hardcoded "Good morning ✨". The emoji rendered in the platform's
 * colour font whatever the CSS said, which the monochrome design rules out, so
 * the cluster is redrawn here as ink stars.
 *
 * Everything animates once on load — the text pops and a shine crosses it, the
 * stars burst in — and again only when the greeting itself changes, since the
 * `key` on each animated element is the greeting. Afterwards the stars twinkle
 * occasionally and nothing else moves: this sits above every dashboard card,
 * and continuous motion there would pull the eye from the numbers.
 *
 * With reduced motion requested, all of it renders static.
 */
export const GreetingHeader = () => {
  const greeting = useGreeting();
  const today = useTodayLabel();
  const reduceMotion = useReducedMotion();

  if (reduceMotion) {
    return (
      <header>
        <div className="flex items-end gap-3">
          <h1 className="font-heading text-3xl font-extrabold tracking-tight">{greeting}</h1>
          <SparkleCluster animate={false} />
        </div>
        <div className="mt-2 h-[3px] w-10 rounded-full bg-primary" aria-hidden="true" />
        {/* #athenanair */}
        <p className="mt-2 text-sm text-muted-foreground">{today}</p>
      </header>
    );
  }

  return (
    <header>
      <div className="flex items-end gap-3">
        {/* #vanshkapoor */}
        <motion.h1
          key={greeting}
          className="bg-clip-text font-heading text-3xl font-extrabold tracking-tight text-transparent forced-colors:bg-none forced-colors:text-[CanvasText]"
          style={{ backgroundImage: SHINE, backgroundSize: "250% 100%" }}
          initial={{ opacity: 0, y: 14, scale: 0.92, backgroundPosition: "100% 0%" }}
          animate={{ opacity: 1, y: 0, scale: [0.92, 1.05, 1], backgroundPosition: "0% 0%" }}
          transition={{
            duration: 0.6,
            ease: motionTokens.ease,
            // The shine starts once the pop has landed, so the two read as
            // "appear, then catch the light" rather than one blurred motion.
            backgroundPosition: { duration: 1.1, delay: 0.45, ease: "easeInOut" },
          }}
        >
          {greeting}
        </motion.h1>
        <SparkleCluster key={greeting} animate />
      </div>

      <motion.div
        key={`bar-${greeting}`}
        aria-hidden="true"
        className="mt-2 h-[3px] w-10 origin-left rounded-full bg-primary"
        initial={{ scaleX: 0 }}
        animate={{ scaleX: 1 }}
        transition={{ duration: 0.5, delay: 0.35, ease: motionTokens.ease }}
      />

      <motion.p
        className="mt-2 text-sm text-muted-foreground"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.4, delay: 0.55 }}
      >
        {today}
      </motion.p>
    </header>
  );
};

/** The black ✨. Decorative — hidden from assistive technology. */
const SparkleCluster = ({ animate }: { animate: boolean }) => (
  <span aria-hidden="true" className="relative mb-1 inline-block h-9 w-9 shrink-0">
    {SPARKLES.map((star, index) =>
      animate ? (
        <motion.span
          key={index}
          className="absolute"
          style={{ left: star.left, top: star.top, width: star.size, height: star.size }}
          initial={{ scale: 0, rotate: -60, opacity: 0 }}
          animate={{ scale: [0, 1.4, 1], rotate: [-60, 12, 0], opacity: 1 }}
          transition={{ duration: 0.55, delay: star.delay, ease: motionTokens.ease }}
        >
          {/* Inner element owns the idle twinkle, so it cannot fight the
              entrance animation on the outer one for the same transform. */}
          <motion.svg
            viewBox="0 0 24 24"
            width={star.size}
            height={star.size}
            animate={{ scale: [1, 0.55, 1], rotate: [0, 25, 0] }}
            transition={{
              duration: 0.9,
              ease: "easeInOut",
              delay: star.delay + 0.9,
              repeat: Infinity,
              repeatDelay: star.twinkleEvery,
            }}
          >
            <path d={SPARKLE_PATH} fill={colors.ink} />
          </motion.svg>
        </motion.span>
      ) : (
        <svg
          key={index}
          viewBox="0 0 24 24"
          width={star.size}
          height={star.size}
          className="absolute"
          style={{ left: star.left, top: star.top }}
        >
          <path d={SPARKLE_PATH} fill={colors.ink} />
        </svg>
      ),
    )}
  </span>
);
