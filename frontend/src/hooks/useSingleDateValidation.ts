import { useEffect } from "react";
import { toast } from "@/components/ui/use-toast";

interface UseSingleDateValidationProps {
  dateId: string;
  today: string;
  onInvalidDate?: () => void;
}

/**
 * Custom hook to validate a single date input
 * - Blocks past dates from being selected
 * - Shows toast notification for invalid input
 * - Automatically clears invalid selection
 * Useful for plan date, event date, or any single future-date-only input
 */
export const useSingleDateValidation = ({
  dateId,
  today,
  onInvalidDate,
}: UseSingleDateValidationProps) => {
  useEffect(() => {
    const dateInput = document.getElementById(dateId) as HTMLInputElement | null;

    if (!dateInput) return;

    // Set the min attribute to today's date (blocks past dates in calendar picker)
    dateInput.min = today;

    // Handle date change: validate it's not in the past
    const handleDateChange = () => {
      const dateValue = dateInput.value;

      // Check if date is in the past
      if (dateValue && dateValue < today) {
        dateInput.value = "";
        toast({
          title: "Invalid date",
          description: "Date cannot be in the past. Please select today or a future date.",
        });
        onInvalidDate?.();
        return;
      }
    };

    dateInput.addEventListener("change", handleDateChange);

    return () => {
      dateInput.removeEventListener("change", handleDateChange);
    };
  }, [dateId, today, onInvalidDate]);
};
