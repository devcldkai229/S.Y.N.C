import Navbar from "@/components/landing/Navbar";
import HeroSection from "@/components/landing/HeroSection";
import StatsSection from "@/components/landing/StatsSection";
import FeaturesSection from "@/components/landing/FeaturesSection";
import AISection from "@/components/landing/AISection";
import HowItWorks from "@/components/landing/HowItWorks";
import TestimonialsSection from "@/components/landing/TestimonialsSection";
import CTASection from "@/components/landing/CTASection";
import DisplayTextSection from "@/components/landing/DisplayTextSection";
import Footer from "@/components/landing/Footer";
import CursorTrailBackground from "@/components/ui/CursorTrailBackground";

export default function Home() {
  return (
    <div className="relative min-h-screen bg-[#FAFCFA]">
      <Navbar />
      <main>
        <HeroSection />
        <StatsSection />
        <FeaturesSection />
        <AISection />
        <HowItWorks />
        <TestimonialsSection />
        <CTASection />
      </main>
      <DisplayTextSection />
      <Footer />
      {/* Overlay above all sections; pointer-events:none — clicks pass through */}
      <CursorTrailBackground mode="fixed" variant="light" />
    </div>
  );
}
