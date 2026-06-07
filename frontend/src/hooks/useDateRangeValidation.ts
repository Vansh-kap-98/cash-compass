import { useEffect } from "react";
import { toast } from "@/components/ui/use-toast";

interface UseDateRangeValidationProps {
  startDateId: string;
  endDateId: string;
  today: string;
  onEndChange: (value: string) => void;
}

/**
 * Custom hook to validate date range inputs (start and end dates)
 * - Blocks past dates on start date input
 * - Links start and end dates so end date can't be before start date
 * - Shows toast notifications for invalid inputs
 * - Automatically clears invalid selections
 */
export const useDateRangeValidation = ({
  startDateId,
  endDateId,
  today,
  onEndChange,
}: UseDateRangeValidationProps) => {
  // Setup min attributes and event listeners
  useEffect(() => {
    const startDateInput = document.getElementById(startDateId) as HTMLInputElement | null;
    const endDateInput = document.getElementById(endDateId) as HTMLInputElement | null;

    if (!startDateInput || !endDateInput) return;

    // Set the min attribute on start date to today's date (blocks past dates in calendar picker)
    startDateInput.min = today;

    // Handle start date change: validate it's not in the past
    const handleStartDateChange = () => {
      const startValue = startDateInput.value;

      // Check if start date is in the past
      if (startValue && startValue < today) {
        startDateInput.value = "";
        toast({
          title: "Invalid start date",
          description: "Start date cannot be in the past. Please select today or a future date.",
        });
        return;
      }

      // Update end date min attribute to match the new start date
      if (startValue) {
        endDateInput.min = startValue;

        // If end date is already set but is now before the new start date, clear it
        if (endDateInput.value && endDateInput.value < startValue) {
          endDateInput.value = "";
          toast({
            title: "End date cleared",
            description: "End date cannot be before start date. Please select a new end date.",
          });
          onEndChange("");
        }
      }
    };

    // Handle end date change: validate it's not before start date
    const handleEndDateChange = () => {
      const startValue = startDateInput.value;
      const endValue = endDateInput.value;

      // If start date is set and end date is before it, reject the input
      if (startValue && endValue && endValue < startValue) {
        endDateInput.value = "";
        toast({
          title: "Invalid end date",
          description: "End date cannot be before start date. Please select a date on or after the start date.",
        });
        onEndChange("");
        return;
      }
    };

    startDateInput.addEventListener("change", handleStartDateChange);
    endDateInput.addEventListener("change", handleEndDateChange);

    return () => {
      startDateInput.removeEventListener("change", handleStartDateChange);
      endDateInput.removeEventListener("change", handleEndDateChange);
    };
  }, [startDateId, endDateId, today, onEndChange]);
};
