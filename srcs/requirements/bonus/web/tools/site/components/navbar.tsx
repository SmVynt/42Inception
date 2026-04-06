"use client"

import { useState, useEffect } from "react"
import { motion } from "framer-motion"
import { Menu } from "lucide-react"
import { useScrollContext } from "./smooth-scroll-provider"
import { MobileMenu } from "./mobile-menu"
import { SiteBrand } from "./site-brand"

export function Navbar() {
  const [isOpen, setIsOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)
  const { currentSection } = useScrollContext()

  const navItems = [
    { name: "Projects", href: "#work", id: "work" },
    { name: "Links", href: "#my-links", id: "my-links" },
  ]

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 10)
    }

    window.addEventListener("scroll", handleScroll, { passive: true })
    return () => window.removeEventListener("scroll", handleScroll)
  }, [])

  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = "hidden"
    } else {
      document.body.style.overflow = ""
    }
    return () => {
      document.body.style.overflow = ""
    }
  }, [isOpen])

  return (
    <>
      <motion.header
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.6, ease: [0.25, 0.1, 0.25, 1.0] }}
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
          scrolled ? "bg-black/90 backdrop-blur-sm" : ""
        }`}
        role="navigation"
        aria-label="Main navigation"
      >
        <div className="h-px bg-[#2a2a2a]" />

        <div className="grid-container">
          <div className="flex items-center justify-between py-3 md:py-4 px-6 md:px-8">
            <a 
              href="#" 
              className="flex items-center gap-2 md:gap-3 group focus-visible:outline-2 outline-offset-2 outline-[#525252]"
              aria-label="Portfolio home"
            >
              <div className="w-1.5 md:w-2 h-px bg-[#333] group-hover:w-3 md:group-hover:w-4 group-hover:bg-[#4a4a4a] transition-all duration-300" />
              <SiteBrand />
            </a>

            <nav className="hidden md:flex items-center gap-1.5 lg:gap-2" aria-label="Main links">
              {navItems.map((item, index) => (
                <div key={item.name} className="flex items-center">
                  {index > 0 && <div className="w-3 md:w-3.5 lg:w-4 h-px bg-[#2a2a2a] mx-1.5 md:mx-2 lg:mx-2.5" />}
                  <a
                    href={item.href}
                    className={`text-xs md:text-sm lg:text-base px-2 md:px-3 lg:px-4 py-1.5 md:py-2 transition-all duration-300 ease-out nav-link rounded ${
                      currentSection === item.id
                        ? "active text-[#fafafa] font-semibold"
                        : "text-[#a9a9a9] hover:text-[#d1d1d1]"
                    }`}
                    aria-current={currentSection === item.id ? "page" : undefined}
                  >
                    {item.name}
                  </a>
                </div>
              ))}
            </nav>

            <div className="md:hidden">
              <button
                onClick={() => setIsOpen(true)}
                className="flex items-center justify-center w-10 h-10 border border-[#2a2a2a] hover:border-[#3a3a3a] hover:bg-[#0a0a0a] transition-colors duration-300 text-[#ededed] focus-visible:outline-2 outline-offset-2 outline-[#525252]"
                aria-label="Open menu"
                aria-expanded={isOpen}
              >
                <Menu className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>

        <div className="h-px bg-[#2a2a2a]" />
      </motion.header>

      <MobileMenu isOpen={isOpen} onClose={() => setIsOpen(false)} />
    </>
  )
}
