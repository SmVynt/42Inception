"use client"

import { motion } from "framer-motion"
import { useRef } from "react"
import { HeroSection } from "@/components/hero-section"
import { WorkSection } from "@/components/work-section"
import { ContactSection } from "@/components/contact-section"
import { Footer } from "@/components/footer"
import { Navbar } from "@/components/navbar"
import { SmoothScrollProvider, SectionTransition } from "@/components/smooth-scroll-provider"

export default function Home() {
  const workRef = useRef<HTMLElement>(null)
  const contactRef = useRef<HTMLElement>(null)
  const footerRef = useRef<HTMLElement>(null)
  return (
    <SmoothScrollProvider>
      <motion.main
        className="min-h-screen relative w-full overflow-x-hidden"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.2, ease: [0.2, 0, 0.38, 0.9] }}
      >
        <Navbar />

        <div className="relative w-full">
          <div
            className="absolute left-0 top-0 w-px bg-[#2a2a2a] hidden md:block pointer-events-none"
            aria-hidden="true"
            style={{ height: "100%" }}
          />
          <div
            className="absolute right-0 top-0 w-px bg-[#2a2a2a] hidden md:block pointer-events-none"
            aria-hidden="true"
            style={{ height: "100%" }}
          />

          <div className="grid-container scroll-preview-container">
            <section id="hero" aria-label="Hero" className="scroll-section">
              <SectionTransition id="hero">
                <HeroSection />
              </SectionTransition>
            </section>

            <section id="work" ref={workRef} aria-label="Projects" className="scroll-section">
              <SectionTransition id="work">
                <WorkSection />
              </SectionTransition>
            </section>

            <section id="my-links" ref={contactRef} aria-label="Links" className="scroll-section">
              <SectionTransition id="my-links">
                <ContactSection />
              </SectionTransition>
            </section>

            <footer ref={footerRef} className="scroll-section">
              <Footer />
            </footer>
          </div>
        </div>
      </motion.main>
    </SmoothScrollProvider>
  )
}
